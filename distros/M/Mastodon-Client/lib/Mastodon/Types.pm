package Mastodon::Types;

use strict;
use warnings;

our $VERSION = '0.016';

use Type::Library -base;

use Type::Utils -all;
use Types::Standard qw( Str HashRef Num );
use Types::Path::Tiny qw( File to_File);

use URI;
use DateTime;
use MIME::Base64;
use Class::Load qw( load_class );

duck_type 'UserAgent', [qw( get post delete )];

class_type 'URI', { class => 'URI' };

coerce 'URI', from Str, via {
  s{^/+}{}g;
  my $uri = URI->new((m{^https?://} ? q{} : 'https://') . $_);
  $uri->scheme('https') unless $uri->scheme;
  return $uri;
};

# We provide our own DateTime type because the Types::DateTime distribution
# is currently undermaintained

class_type 'DateTime', { class => 'DateTime' };

class_type 'HTTPResponse', { class => 'HTTP::Response' };

coerce 'DateTime',
  from Num,
    via { 'DateTime'->from_epoch( epoch => $_ ) }
  from Str,
    via {
      require DateTime::Format::Strptime;
      DateTime::Format::Strptime->new(
        pattern   => '%FT%T.%3N%Z',
        on_error  => 'croak',
      )->parse_datetime($_);
    };

# Validation here could be improved
# It is either a username if a local account, or a username@instance.tld
# but what characters are valid?
declare 'Acct', as Str;

declare 'Image',
  as Str, where { m{^data:image/(?:png|jpeg);base64,[a-zA-Z0-9/+=\n]+$} };

coerce File, from Str, via {
  require Path::Tiny;
  return Path::Tiny::path( $_ );
};

coerce 'Image',
  from File->coercibles,
  via {
    my $file = to_File($_);
    require Image::Info;
    require MIME::Base64;
    my $type = lc Image::Info::image_type( $file->stringify )->{file_type};
    my $img = "data:image/$type;base64,"
      . MIME::Base64::encode_base64( $file->slurp_raw );
    return $img;
  };

# Entity types

my @entities = qw(
  Status Account Instance Attachment Card Context Mention
  Notification Relationship Report Results Error Tag Application
);

foreach my $name (@entities) {
  class_type $name, { class => "Mastodon::Entity::$name" };
  coerce $name, from HashRef, via {
    load_class "Mastodon::Entity::$name";
    "Mastodon::Entity::$name"->new($_);
  };
}

role_type 'Entity', { role => 'Mastodon::Role::Entity' };

coerce 'Instance',
  from Str,
    via {
      require Mastodon::Entity::Instance;
      Mastodon::Entity::Instance->new({
        uri => $_,
      });
    };

coerce 'Entity',
  from HashRef,
    via {
      my $hash = $_;
      my $entity;

      use Try::Tiny;
      foreach my $name (@entities) {
        $entity = try {
          load_class "Mastodon::Entity::$name";
          "Mastodon::Entity::$name"->new($hash);
        };
        last if defined $entity;
      }

      return $entity;
    };

1;
