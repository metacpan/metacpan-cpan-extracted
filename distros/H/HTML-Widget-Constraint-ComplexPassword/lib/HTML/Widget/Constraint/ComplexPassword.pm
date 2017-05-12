package HTML::Widget::Constraint::ComplexPassword;

=head1 NAME

HTML::Widget::Constraint::ComplexPassword - HTML::Widget form constraint that checks if the field is a complex password.

=head1 SYNOPSIS

	use HTML::Widget;
	
	my $widget = HTML::Widget->new('widget')->method('get')->action('/');
	
	...
	
	#constraints
	$widget->constraint('Length'          => @columns)
		->min($HTML::Widget::Constraint::ComplexPassword::MIN_LENGTH)
		->message('Must be at least '.$HTML::Widget::Constraint::ComplexPassword::MIN_LENGTH.' characters long');
	$widget->constraint('ComplexPassword' => @columns)
		->message(qq{
			Must contain at least one upper and one lower case character.
			Must contain at least one number or a special character -
			"$HTML::Widget::Constraint::ComplexPassword::SPECIAL_CHARACTERS"
		)};
	
	#or this will be enought but then the error text is too long
	$widget->constraint(ComplexPassword => @columns)
		->message(qq{
			Must contain at least $HTML::Widget::Constraint::ComplexPassword::MIN_LENGTH characters and include
			one upper and one lower case character. Must contain at least one number or a
			special character - "$HTML::Widget::Constraint::ComplexPassword::SPECIAL_CHARACTERS"
		});

=head1 DESCRIPTION

A constraint for L<HTML::Widget> to check if the password is complex enought. Password must have
at least MIN_LENGTH characters count, one lower case character is required, one upper case character
is required and either number or one of SPECIAL_CHARACTERS is needed.

=head2 EXPORTS 

	our $MIN_LENGTH = 8;
	our $NUMBER_CHARACTERS  = '0123456789';
	our $SPECIAL_CHARACTERS = '~`!@#$%^&*()-_+={}[]\\|:;"\'<>,.?/';

=head2 TIPS

If you want to force different password lenght then do:

	use HTML::Widget::Constraint::ComplexPassword;
	$HTML::Widget::Constraint::ComplexPassword::MIN_LENGTH = 10;

or

	$widget->constraint(ComplexPassword => @columns)
		->min_length(10)
		->message("bla bla");

If you want just numbers and no other special characters then remove characters from the
SPECIAL_CHARACTERS list:

	use HTML::Widget::Constraint::ComplexPassword;
	$HTML::Widget::Constraint::ComplexPassword::SPECIAL_CHARACTERS = '';

You can change both NUMBER_CHARACTERS and SPECIAL_CHARACTERS if you really need to.

=head1 TODO

It will be nice to have more variants of "complexity". Let's say we can create
method ->level($level_type) that will switch between them. For me this default
is enought. If you have different demant just drop me an email and i can include it
here may be somebody else will reuse.

=cut

use warnings;
use strict;
use base 'HTML::Widget::Constraint';

our $VERSION = '0.01';

use Exporter 'import';
our @EXPORT_OK    = qw(
	$MIN_LENGTH
	$SPECIAL_CHARACTERS
);

our $MIN_LENGTH = 8;
our $NUMBER_CHARACTERS  = '0123456789';
our $SPECIAL_CHARACTERS = '~`!@#$%^&*()-_+={}[]\\|:;"\'<>,.?/';

=head1 METHODS

=over 4

=cut

__PACKAGE__->mk_accessors(qw{
	min_length
});

=item min_length()

Set minimum length of password just for current widget.

=item validate($value)

Perform validation $value validation.

Return true or false if the password is or isn't ok.

=cut

sub validate {
    my $self  = shift;
    my $value = shift;

	#undefined value is not valid
    return 0 if not defined $value;

	#must have some length
    return 0 if length($value) < ($self->min_length || $MIN_LENGTH);
	
	#must have one upper case character
	return 0 if not $value =~ m{[A-Z]};

	#must have one lower case character
	return 0 if not $value =~ m{[a-z]};

	#must have one special character or number
	my $special_char;
	my $dup_value = $value;
	while ($special_char = chop($dup_value)) {
		last if (index($SPECIAL_CHARACTERS, $special_char) != -1);
	}
	my $number_char;
	$dup_value = $value;
	while ($number_char = chop($dup_value)) {
		last if (index($NUMBER_CHARACTERS, $number_char) != -1);
	}
	return 0 if (
		($special_char eq '')  #special char
		and
		($number_char eq '')   #number char
	);

	#if it passed until here it's valid
    return 1;
}

=back

=cut

1;

__END__

=head1 SEE ALSO

L<HTML::Widget>

=head1 AUTHOR

Jozef Kutej, E<lt>jozef@kutej.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jozef Kutej

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut



