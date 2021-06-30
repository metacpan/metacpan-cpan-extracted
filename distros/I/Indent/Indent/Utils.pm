package Indent::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

# Constants.
Readonly::Scalar my $DEFAULT_TAB_LENGTH => 8;
Readonly::Scalar my $SPACE => q{ };

our $VERSION = 0.08;

# Length of tab.
our $TAB_LENGTH = $DEFAULT_TAB_LENGTH;

# Export.
our @EXPORT_OK = qw(line_size_check reduce_duplicit_ws remove_first_ws
	remove_last_ws remove_ws string_len);

# Line size check.
sub line_size_check {
	my $self = shift;
	if (! defined $self->{'line_size'}
		|| $self->{'line_size'} !~ m/^\d+$/ms) {

		err '\'line_size\' parameter must be a positive number.',
			'line_size', $self->{'line_size'};
	}
	return;
}

# Reduce duplicit blank space in string to one space.
# @param $string Reference to data string.
sub reduce_duplicit_ws {
	my $string_sr = shift;
	${$string_sr} =~ s/\s+/\ /gms;
	return;
}

# Remove blank characters in begin of string.
# @param $string Reference to data string.
sub remove_first_ws {
	my $string_sr = shift;
	${$string_sr} =~ s/^\s*//ms;
	return;
}

# Remove blank characters in end of string.
# @param $string Reference to data string.
sub remove_last_ws {
	my $string_sr = shift;
	${$string_sr} =~ s/\s*$//ms;
	return;
}

# Remove white characters in begin and end of string.
# @param $string reference to data string.
sub remove_ws {
	my $string_sr = shift;
	remove_last_ws($string_sr);
	remove_first_ws($string_sr);
	return;
}

# Gets length of string.
# @param $string Data string.
# @return $length_of_string Length of data string, when '\t' translate to
# $TAB_LENGTH x space.
sub string_len {
	my $string = shift;
	my $tmp = $SPACE x $TAB_LENGTH;
	$string =~ s/\t/$tmp/gms;
	my $length_of_string = length $string;
	return $length_of_string;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

 Indent::Utils - Utilities for Indent classes.

=head1 SYNOPSIS

 use Indent::Utils qw(line_size_check reduce_duplicit_ws remove_first_ws
         remove_last_ws remove_ws string_len);

 line_size_check($object_with_line_size_parameter);
 reduce_duplicit_ws(\$string);
 remove_first_ws(\$string);
 remove_last_ws(\$string);
 remove_ws(\$string);
 my $length_of_string = string_len($string);

=head1 GLOBAL VARIABLES

=over 8

=item C<TAB_LENGTH>

 Default length of tabelator is 8 chars.

=back

=head1 SUBROUTINES

=head2 C<line_size_check>

 line_size_check($object_with_line_size_parameter);

Line size 'line_size' parameter check.

=head2 C<reduce_duplicit_ws>

 reduce_duplicit_ws(\$string);

Reduce duplicit blank space in string to one space.

=head2 C<remove_first_ws>

 remove_first_ws(\$string);

Remove blank characters in begin of string.

=head2 C<remove_last_ws>

 remove_last_ws(\$string);

Remove blank characters in end of string.

=head2 C<remove_ws>

 remove_ws(\$string);

Remove white characters in begin and end of string.

=head2 C<string_len>

 my $length_of_string = string_len($string);

Gets length of string.

=head1 ERRORS

 line_size_check():
         'line_size' parameter must be a positive number.
                 'line_size', %s

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Indent::Utils qw(reduce_duplicit_ws);

 my $input = 'a  b';
 reduce_duplicit_ws(\$input);
 print "$input|\n";

 # Output:
 # a b|

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Indent::Utils qw(remove_first_ws);

 my $input = '  a';
 remove_first_ws(\$input);
 print "$input|\n";

 # Output:
 # a|

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Indent::Utils qw(remove_last_ws);

 my $input = 'a   ';
 remove_last_ws(\$input);
 print "$input|\n";

 # Output:
 # a|

=head1 EXAMPLE4

 use strict;
 use warnings;

 use Indent::Utils qw(remove_ws);

 my $input = '   a   ';
 remove_ws(\$input);
 print "$input|\n";

 # Output:
 # a|

=head1 EXAMPLE5

 use strict;
 use warnings;

 use Indent::Utils qw(string_len);

 # Print string length.
 print string_len("\tab\t")."\n";

 # Output:
 # 18

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Indent>

Class for indent handling.

=item L<Indent::Block>

Class for block indenting.

=item L<Indent::Data>

Class for data indenting.

=item L<Indent::String>

Class for text indenting.

=item L<Indent::Word>

Class for word indenting.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Indent>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2005-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
