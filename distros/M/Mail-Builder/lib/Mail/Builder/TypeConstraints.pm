# ============================================================================
package Mail::Builder::TypeConstraints;
# ============================================================================

use strict;
use warnings;

use namespace::autoclean;
use Moose::Util::TypeConstraints;

use Scalar::Util qw(blessed);
use Path::Class::File;

our $VERSION = $Mail::Builder::VERSION;
our $TLDCHECK = Class::Load::try_load_class('Net::Domain::TLD'),
our %EMAILVALID = (
    'tldcheck'     => $TLDCHECK,
);

our $TIMEPART_RE = qr/[0-5]?\d/;

# Simple types

subtype 'Mail::Builder::Type::Date'
    => as 'Str'
    => where { m/^
        ( Sun | Mon | Tue | Wed | Thu | Fri | Sat )
        ,
        \s
        ( 3[01] | [12] \d | 0? [1-9] )
        \s
        ( Jan | Feb | Mar | Apr | May | Jun | Jul | Aug | Sep | Oct | Nov | Dec )
        \s
        \d{4}
        \s
        ( 2[0-3] | 1\d | 0?\d )
        :
        $TIMEPART_RE
        :
        $TIMEPART_RE
        \s
        [+-]\d{4}
    $/xi };

subtype 'Mail::Builder::Type::DateTime'
    => as Object
    => where { $_->isa('DateTime') }
    => as Int
    => where {
        require Email::Date::Format;
        Email::Date::Format::email_date($_);
    };

coerce 'Mail::Builder::Type::Date'
    => from 'Mail::Builder::Type::DateTime'
    => via {
        return $_->clone->set_locale('en')->format_cldr("ccc, dd MMM yyyy hh:mm:ss ZZZ")
    };

subtype 'Mail::Builder::Type::Content'
    => as 'ScalarRef';

subtype 'Mail::Builder::Type::File'
    => as class_type('Path::Class::File')
    => where { -f $_ && -r _ }
    => message { "Could not open file '$_'" };

subtype 'Mail::Builder::Type::Fh'
    => as class_type('IO::File');

coerce 'Mail::Builder::Type::Fh'
    => from 'GlobRef'
    => via {
        return bless($_,'IO::File');
    };

coerce 'Mail::Builder::Type::File'
    => from 'Str'
    => via {
        return Path::Class::File->new($_)
    };

subtype 'Mail::Builder::Type::EmailAddress'
    => as 'Str'
    => where {
        my %params;
        foreach my $param (qw(rfc822 local_rules fqdn mxcheck tldcheck)) {
            $params{'-'.$param} = $EMAILVALID{$param}
                if defined $EMAILVALID{$param};
        }
        lc $_ eq lc (Email::Valid->address(
            %params,
            -address => $_,
        ) // '');
    }
    => message { "'$_' is not a valid e-mail address" };

subtype 'Mail::Builder::Type::Class'
    => as 'Str'
    => where { m/^Mail::Builder::(.+)$/ && Class::Load::is_class_loaded($_) }
    => message { "'$_' is not a  Mail::Builder::* class" };

subtype 'Mail::Builder::Type::Priority'
    => as enum([qw(1 2 3 4 5)]);

subtype 'Mail::Builder::Type::ImageMimetype'
    => as enum([qw(image/gif image/jpeg image/png)])
    => message { "'$_' is not a valid image MIME-type" };


subtype 'Mail::Builder::Type::Mimetype'
    => as 'Str'
    => where { m/^(image|message|text|video|x-world|application|audio|model|multipart)\/[^\/]+$/ }
    => message { "'$_' is not a valid MIME-type" };

# Class types

subtype 'Mail::Builder::Type::Address'
    => as class_type('Mail::Builder::Address');

coerce 'Mail::Builder::Type::Address'
    => from 'Defined'
    => via { Mail::Builder::Address->new( $_ ) };

subtype 'Mail::Builder::Type::AddressList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Address' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Address" };

coerce 'Mail::Builder::Type::AddressList'
    => from 'Mail::Builder::Type::Address'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [ $_ ] ) }
    => from 'Str'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [ Mail::Builder::Address->new($_) ] ) }
    => from 'HashRef'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [ Mail::Builder::Address->new($_) ] ) }
    => from class_type('Email::Address')
    => via {
        return Mail::Builder::List->new( type => 'Mail::Builder::Address', list => [
            Mail::Builder::Address->new($_)
        ] )
    }
    => from 'ArrayRef'
    => via {
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Address')) {
                push(@{$result},$element);
            } else {
                push(@{$result},Mail::Builder::Address->new($element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Address', list => $result )
    };

subtype 'Mail::Builder::Type::Attachment'
    => as class_type('Mail::Builder::Attachment');

subtype 'Mail::Builder::Type::AttachmentList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Attachment' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Attachment" };

coerce 'Mail::Builder::Type::AttachmentList'
    => from class_type('Mail::Builder::Attachment')
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => [ $_ ] ) }
    => from 'HashRef'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => [ Mail::Builder::Attachment->new($_) ] ) }
    => from 'ArrayRef'
    => via {
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Attachment')) {
                push(@{$result},$element);
            } elsif (ref $element eq 'HASH') {
                push(@{$result},Mail::Builder::Attachment->new($element));
            } else {
                push(@{$result},Mail::Builder::Attachment->new(file => $element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Attachment', list => $result )
    };

subtype 'Mail::Builder::Type::Image'
    => as class_type('Mail::Builder::Image');

subtype 'Mail::Builder::Type::ImageList'
    => as class_type('Mail::Builder::List')
    => where { $_->type eq 'Mail::Builder::Image' }
    => message { "'$_' is not a Mail::Builder::List of Mail::Builder::Image" };

coerce 'Mail::Builder::Type::ImageList'
    => from class_type('Mail::Builder::Image')
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Image', list => [ $_ ] ) }
    => from 'HashRef'
    => via { Mail::Builder::List->new( type => 'Mail::Builder::Image', list => [ Mail::Builder::Image->new($_) ] ) }
    => from 'ArrayRef'
    => via {
        my $param = $_;
        my $result = [];
        foreach my $element (@$param) {
            if (blessed $element
                && $element->isa('Mail::Builder::Image')) {
                push(@{$result},$element);
            } elsif (ref $element eq 'HASH') {
                push(@{$result},Mail::Builder::Image->new($element));
            } else {
                push(@{$result},Mail::Builder::Image->new(file => $element));
            }
        }
        return Mail::Builder::List->new( type => 'Mail::Builder::Image', list => $result )
    };

1;