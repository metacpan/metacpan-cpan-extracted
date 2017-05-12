package Egg::Plugin::Encode;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Encode.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

sub _setup {
	my($e)= @_;
	no warnings 'redefine';
	if (my $icode= $e->config->{character_in}) {
		my $class= $e->global->{request_class};
##		my $code = $class->can('parameters')
##		        || \&Egg::Request::handler::parameters;
		my $code = \&Egg::Request::handler::parameters;
		no strict 'refs';  ## no critic.
		no warnings 'redefine';
		*{"${class}::parameters"}= sub {
			$_[0]->{parameters} ||= do {
				tie my %param,
				'Egg::Plugin::Encode::TieHash', $e, $icode, $code->(@_);
				\%param;
			  };
		  };
		*{"${class}::params"}= $class->can('parameters');
	}
	my $encode= $e->create_encode;
	no warnings 'redefine';
	*encode= sub { $encode };
	$e->next::method;
}

sub create_encode {
	require Jcode;
	Jcode->new('jcode context.');
}
sub utf8_conv { shift->encode->set(@_)->utf8 }
sub sjis_conv { shift->encode->set(@_)->sjis }
sub euc_conv  { shift->encode->set(@_)->euc  }

package Egg::Plugin::Encode::TieHash;
use strict;
use warnings;
use Tie::Hash;

our @ISA= 'Tie::ExtraHash';

my $conv;

sub TIEHASH {
	my($class, $e, $icode, $param)= @_;
	$conv= "${icode}_conv";
	bless [$param, $e, {}], $class;
}
sub FETCH {
	my($self, $key)= @_;
	return "" unless exists($self->[0]{$key});
	return $self->[0]{$key} if $self->[2]{$key};
	$self->[2]{$key}= 1;
	my $value= \$self->[0]{$key};
	if (ref($$value) eq 'Fh') {
		return $$value;
	} elsif (ref($$value) eq 'ARRAY') {
		for (@$value) { tr/\r//d; $self->[1]->$conv(\$_) }
		return wantarray ? @$value: $value;
	}else {
		$$value=~tr/\r//d;
		return $$value= $self->[1]->$conv($value);
	}
}
sub STORE {
	my($self, $key)= splice @_, 0, 2;
	$self->[2]{$key}= 1 unless $self->[2]{$key};
	$self->[0]{$key}= shift;
}

1;

__END__

=head1 NAME

Egg::Plugin::Encode - Conversion function of character.

=head1 SYNOPSIS

  use Egg qw/ Encode /;
  
  my $utf8= $e->utf_conv($text);
  my $sjis= $e->sjis_conv($text);
  my $euc = $e->euc_conv($text);

=head1 DESCRIPTION

Plugin that offers method of converting character-code.

The character-code is converted with L<Jcode>.

The supported character-code is 'euc', 'sjis', 'utf8'.

Please make the 'create_encode' method in the project, and return the object that
does the code conversion from the method when converting it excluding L<Jcode>.

  sub create_encode {
     AnyComvert->new;
  }

It sets it up so that all the input received with L<Egg::Request> is united by
the character-code when 'character_in' is defined by the configuration of Egg.

If it wants to treat the code not supported by this plugin, the code conversion
can be done in that making the method in which '[code_name]_conv' in the project.
And, when the [code_name] is set to 'character_in', the input united by a target
code comes to be received.

  sub anyname_conv {
    shift->encode->set(@_)->anyname;
  }
  
  # Egg configuration.
  
  character_in => 'anyname',

=head1 METHODS

=head2 encode

The object obtained by the 'create_encode' method is returned.

  my $conv_text= $e->encode->set(\$text)->utf8;

=head2 create_encode

The object to convert the character-code is returned.

L<Jcode> is restored in default.

If the object that treats the character-code is changed, this method is overwrited
as a controller etc.

=head2 utf8_conv ([TEXT])

The character-code is converted into utf8.

  my $utf8= $e->utf_conv(\$text);

=head2 sjis_conv ([TEXT]);

The character-code is converted into Shift_JIS.

  my $sjis= $e->sjis_conv(\$text);

=head2 euc_conv ([TEXT]);

The character-code is converted into EUC-JP.

  my $euc= $e->euc_conv(\$text);

=head1 BUGS

Jcode.pm is used and note the point that is always utf8 about the content, please
if you do not receive the conversion result when the character to be converted
into the method of *_ conv is passed by the SCALAR reference though it is not
a translation of bug.
This is because of being internally processed with utf8 in the specification of 
Jcode.

  my $text= 'test'; # For shift_jis.
  $e->euc_conv(\$text);        # The content of $text is utf8.
  $text= $e->euc_conv(\$text); # The content of $text is euc.
  
  $e->utf8_conv(\$text);       # This is untouched utf8.

Perhaps, I think that it is a peculiar problem when L<Jcode> operates as Wrapper
of L<Encode> module.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Jcode>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

