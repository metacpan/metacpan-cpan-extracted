package MIME::Expander::Guess::FileName;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

use base qw(MIME::Expander::Guess);
use MIME::Type::FileName;

sub type {
    my $class = shift;
    my $ref_contents = shift;
    my $info = shift || {};
    my $name = $info->{filename};

    return undef unless( defined $name );

    my $mime = MIME::Type::FileName::guess($name);

    return undef if( $mime and $mime eq 'application/octet-stream' );

    return $mime;
}

1;
__END__


=pod

=head1 NAME

MIME::Expander::Guess::FileName - An implementation for guessing mime type

=head1 SYNOPSIS

    use MIME::Expander;
    use IO::All;
    
    my $filename = $ARGV[0];
    my $contents < io $filename;

    my $me = MIME::Expander->new({
                    guess_type => ['MMagic','FileName'],
                    });

    my $type = $me->guess_type_by_contents(
                \$contents, {filename => $filename});

=head1 DESCRIPTION

Guess the mime type from filename using L<MIME::Type::FileName>.

=head1 SEE ALSO

L<MIME::Expander::Guess>

L<MIME::Type::FileName>

=cut
