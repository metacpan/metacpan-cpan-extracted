package MIME::Expander::Guess;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

sub type {
    my $class = shift;
    my $ref_contents = shift;
    my $info = shift || {};
    return 'application/octet-stream';
}


1;
__END__

=pod

=head1 NAME

MIME::Expander::Guess - An interface of classes determine mime type.

=head1 SYNOPSIS

    package MyGuessRoutine;
    use base 'MIME::Expander::Guess';

    sub type {
        my $class = shift;
        my $ref_contents = shift;
        my $info = shift || { filename => 'name.suffix' };
    
        # ...
    
        return lc('type/sub-type');
    }
    
=head1 DESCRIPTION

It have only class method 'type' which guess type from contents.

You have to implement a class method 'type', determine and return the mime type as lower case string.

If it could not determine, return the undef.

=head1 SEE ALSO

L<MIME::Expander::Guess::FileName>

L<MIME::Expander::Guess::MMagic>

=cut
