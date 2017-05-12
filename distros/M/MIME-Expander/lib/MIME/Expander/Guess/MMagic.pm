package MIME::Expander::Guess::MMagic;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

use parent qw(MIME::Expander::Guess);
use File::MMagic;

sub type {
    my $class = shift;
    my $ref_contents = shift;
    my $info = shift || {};
    my $data = substr($$ref_contents, 0, 0x8564);
    return File::MMagic->new->checktype_contents($data);
}

1;
__END__


=pod

=head1 NAME

MIME::Expander::Guess::MMagic - An implementation for guessing mime type

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

Guess the mime type from contents using L<File::MMagic>.

=head1 SEE ALSO

L<MIME::Expander::Guess>

L<File::MMagic>

=cut
