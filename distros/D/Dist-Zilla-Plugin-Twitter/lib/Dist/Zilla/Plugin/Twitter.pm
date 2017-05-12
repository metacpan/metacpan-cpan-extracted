package Dist::Zilla::Plugin::Twitter;
use 5.008;
use strict;
use warnings;
use utf8;
# ABSTRACT: Twitter when you release with Dist::Zilla
our $VERSION = '0.026'; # VERSION

use Dist::Zilla 4 ();
use Moose 0.99;
use Net::Twitter 4.00001 ();  # API v1.1 support
use WWW::Shorten::Simple ();  # A useful interface to WWW::Shorten
use WWW::Shorten 3.02 ();     # For latest updates to dead services
use WWW::Shorten::TinyURL (); # Our fallback
use namespace::autoclean 0.09;
use Try::Tiny;


# extends, roles, attributes, etc.
with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::TextTemplate';

has 'tweet' => (
  is  => 'ro',
  isa => 'Str',
  default => 'Released {{$DIST}}-{{$VERSION}}{{$TRIAL}} {{$URL}} !META{resources}{repository}{web}'
);

has 'tweet_url' => (
  is  => 'ro',
  isa => 'Str',
  default => 'https://metacpan.org/release/{{$AUTHOR_UC}}/{{$DIST}}-{{$VERSION}}/',
);

has 'url_shortener' => (
  is    => 'ro',
  isa   => 'Str',
  default => 'TinyURL',
);

has 'hash_tags' => (
  is  => 'ro',
  isa => 'Str',
);

has 'config_file' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        require File::Spec;
        require Dist::Zilla::Util;

        return File::Spec->catfile(
            $self->config_dir,
            'twitter.ini'
        );
    }
);

has 'config_dir' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        require Dist::Zilla::Util;
        my $dir = Dist::Zilla::Util->_global_config_root();
        return $dir->stringify;
    },
);

has 'consumer_tokens' => (
  is => 'ro',
  isa => 'HashRef',
  lazy => 1,
  default => sub {
    return { grep tr/a-zA-Z/n-za-mN-ZA-M/, map $_, # rot13
        pbafhzre_xrl      => 'fdAdffgTXj6OiyoH0anN',
        pbafhzre_frperg   => '3J25ATbGmgVf1vO0miwz3o7VjRoXC7Y9y5EfLGaUfTL',
    };
  },
);

has 'twitter' => (
    is => 'ro',
    isa => 'Net::Twitter',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $nt = Net::Twitter->new(
            useragent_class => $ENV{DZ_TWITTER_USERAGENT} || 'LWP::UserAgent',
            traits => [qw/ API::RESTv1_1 OAuth /],
            ssl => 1,
            %{ $self->consumer_tokens },
        );

        try {
            require Config::INI::Reader;
            my $access = Config::INI::Reader->read_file( $self->config_file );

            $nt->access_token( $access->{'api.twitter.com'}->{access_token} );
            $nt->access_token_secret( $access->{'api.twitter.com'}->{access_secret} );
        }
        catch {
            $self->log("Error: $_");

            my $auth_url = $nt->get_authorization_url;
            $self->log(__PACKAGE__ . " isn't authorized to tweet on your behalf yet");
            $self->log("Go to $auth_url to authorize this application");
            my $pin = $self->zilla->chrome->prompt_str('Enter the PIN: ');
            chomp $pin;
            # Fetches tokens and sets them in the Net::Twitter object
            my @access_tokens = $nt->request_access_token(verifier => $pin);

            unless ( -d $self->config_dir ) {
                require File::Path;
                File::Path::make_path( $self->config_dir );
            }

            require Config::INI::Writer;
            Config::INI::Writer->write_file( {
                'api.twitter.com' => {
                    access_token => $access_tokens[0],
                    access_secret => $access_tokens[1],
                }
            }, $self->config_file );

            try {
                chmod 0600, $self-> config_file;
            }
            catch {
                print "Couldn't make @{[ $self->config_file ]} private: $_";
            };
        };

        return $nt;
    },
);


# methods

sub after_release {
    my $self = shift;
    my $tgz = shift || 'unknowntarball';
    my $zilla = $self->zilla;

    my $cpan_id = '';
    for my $plugin ( @{ $zilla->plugins_with( -Releaser ) } ) {
      if ( my $user = eval { $plugin->user } || eval { $plugin->username } ) {
        $cpan_id = uc $user;
        last;
      }
    }
    confess "Can't determine your CPAN user id from a release plugin"
      unless length $cpan_id;

    my $path = substr($cpan_id,0,1)."/".substr($cpan_id,0,2)."/$cpan_id";

    my $stash = {
      DIST => $zilla->name,
      ABSTRACT => $zilla->abstract,
      VERSION => $zilla->version,
      TRIAL   => ( $zilla->is_trial ? '-TRIAL' : '' ),
      TARBALL => "$tgz",
      AUTHOR_UC => $cpan_id,
      AUTHOR_LC => lc $cpan_id,
      AUTHOR_PATH => $path,
    };
    my $module = $zilla->name;
    $module =~ s/-/::/g;
    $stash->{MODULE} = $module;

    my $longurl = $self->fill_in_string($self->tweet_url, $stash);
    $stash->{URL} = $self->_shorten( $longurl );

    my $msg = $self->fill_in_string( $self->tweet, $stash);

    $DB::single = 1;

    {
        no warnings qw/ uninitialized /;
        $msg =~ s/
        (?<modifier>[!@]?)
        META
        (?<access>
          (?:
            \{ [^}]+  \}
            |
            \[ [0-9]+ \]
          )
        +)
        /
            ( $+{modifier} eq '!' ? '$self->_shorten('  : '' )
          . ( $+{modifier} eq '@' ? 'join($", @{'       : '' )
          . '$self->zilla->distmeta->' . $+{access}
          . ( $+{modifier} eq '@' ? '})'                : '' )
          . ( $+{modifier} eq '!' ? ')'                 : '' )
        /xeeg;
        warn $@ if $@;
    }

    if (defined $self->hash_tags) {
        $msg .= " " . $self->hash_tags;
    }
    $msg =~ tr/ //s; # squeeze multiple consecutive spaces into just one

    try {
        $self->twitter->update($msg);
        $self->log($msg);
    }
    catch {
        $self->log("Couldn't tweet: $_");
        $self->log("Tweet would have been: $msg");
    };

    return 1;
}


sub _shorten {
    my( $self, $url ) = @_;

    unless ( $self->url_shortener and $self->url_shortener !~ m/^(?:none|twitter|t\.co)$/ ) {
      $self->log('dist.ini specifies to not use a URL shortener; using full URL');
      return $url;
    }

    foreach my $service (($self->url_shortener, 'TinyURL')) { # Fallback to TinyURL on errors
        my $shortener = WWW::Shorten::Simple->new($service);
        $self->log("Trying $service");
        if ( my $short = eval { $shortener->shorten($url) } ) {
            return $short;
        }
    }

    return $url;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Twitter - Twitter when you release with Dist::Zilla

=head1 VERSION

version 0.026

=head1 SYNOPSIS

In your F<dist.ini>:

    [Twitter]
    hash_tags = #foo
    url_shortener = TinyURL

=head1 DESCRIPTION

This plugin will use L<Net::Twitter> to send a release notice to Twitter.
By default, it will include a link to release on L<http://metacpan.org>.

The default configuration is as follows:

    [Twitter]
    tweet_url = https://metacpan.org/release/{{$AUTHOR_UC}}/{{$DIST}}-{{$VERSION}}/
    tweet = Released {{$DIST}}-{{$VERSION}}{{$TRIAL}} {{$URL}} !META{resources}{repository}{web}
    url_shortener = TinyURL

The C<tweet_url> is shortened with L<WWW::Shorten::TinyURL> or
whichever other service you choose (use 'none' to use the full URL,
in which case Twitter will shorten it for you) and appended to the
C<tweet> message.

=head2 VARIABLE INTERPOLATION

The following variables are available for substitution in the URL
and message templates:

      DIST        # Foo-Bar
      MODULE      # Foo::Bar
      ABSTRACT    # Foo-Bar is a module that FooBars
      VERSION     # 1.23
      TRIAL       # -TRIAL if is_trial, empty string otherwise.
      TARBALL     # Foo-Bar-1.23.tar.gz
      AUTHOR_UC   # JOHNDOE
      AUTHOR_LC   # johndoe
      AUTHOR_PATH # J/JO/JOHNDOE
      URL         # http://tinyurl.com/...

=head3 DISTMETA INTERPOLATION

Resources information available in the META.* files of the distribution
can be accessed via C<<META{key}{subkey}[1]>>. You may mix-and-match
C<{...}> to access hashref elements and C<[\d]> to access arrayref elements.
You're responsible for making sure you are accessing the right part of
the META data structure, and treating it as the right type of data. See
L<CPAN::Meta::Spec> and the "$TYPE DATA" sections of L<CPAN::Meta> in
particular.

The C<< META{...} >> replacement may also have one of two modifiers, which
are prefixed directly before C<META>:

=over 4

=item C<!> - URL shortening

Providing an exclamation point (C<< !META{...} >>) will URL-shorten the value
you extract from the distmeta data structure. This will have no effect unless
the value is a URL to begin with.

=item C<@> - Arrayref stringification

Providing an at-symbol (C<< @META{...} >>) will include all the elements of
the arrayref you specify by joining them with C<$">. So, this is just like
doing C<< "@{ $your_array_ref }" >>.

=back

So, for example, to use the GitHub home of the project instead of its metacpan
page, one can do:

    [Twitter]
    tweet = Released {{$DIST}}-{{$VERSION}}{{$TRIAL}} !META{resource}{repository}{web}
    url_shortener = TinyURL

Or, to include the authors in your tweet:

    [Twitter]
    tweet = @META{author} released {{$MODULE}} {{$VERSION}}: {{$URL}}

=head2 PAUSEID

You must be using the C<UploadToCPAN> or C<FakeRelease> plugin for this plugin to
determine your PAUSEID.

=head2 HASHTAGS

You can use the C<hash_tags> option to append hash tags (or anything,
really) to the end of the message generated from C<tweet>.

    [Twitter]
    hash_tags = #perl #cpan #foo

=for test_synopsis 1;
__END__

=for Pod::Coverage after_release

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Twitter/>.

=head1 SOURCE

The development version is on github at L<http://github.com/dagolden/dist-zilla-plugin-twitter>
and may be cloned from L<git://github.com/dagolden/dist-zilla-plugin-twitter.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/dagolden/dist-zilla-plugin-twitter/issues>.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
