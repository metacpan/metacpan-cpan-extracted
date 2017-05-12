package Lingua::AR::Word;

use strict;
use warnings;
use utf8;


use Lingua::AR::Word::Stem;	#needed to find the stem
use Lingua::AR::Word::Encode;	#needed to encode into ArabTeX


our $VERSION = '1.5.7';


sub new{

    my $class=shift;

    my $this={
        _word=>shift,
        _stem=>"",
        _arabtex=>""
    };

    $this->{_stem}=&stem($this->{_word});
    $this->{_arabtex}=&encode($this->{_word});

    bless($this,$class);
}



sub get_word{
    $_[0]->{_word};
}

sub get_stem{
    $_[0]->{_stem};
}

sub get_arabtex{
    $_[0]->{_arabtex};
}



1;
__END__

=head1 NAME

Lingua::AR::Word - Perl extension to get the stem and ArabTeX encoding of Arabic words

=head1 SYNOPSIS

	use utf8;
	use Lingua::AR::Word;

	my $word=Lingua::AR::Word->new("ARABIC_WORD_IN_UTF8");

	open FOUTPUT, ">>:utf8", "output" or die "Cannot create output file: $!\n";
	

	print FOUTPUT $word->get_word();
	print FOUTPUT $word->get_stem();
	print FOUTPUT $word->get_arabtex();

	close FOUTPUT;


=head1 DESCRIPTION

In order to work on an Arabic word, you need to create the object Lingua::AR::Word, passing the Arabic word encoded in utf8 to the constructor.
You will then be able to get the stem through get_stem().
You will get the ArabTeX translittered form through get_arabtex().

Remember that input-output directly to shell will not be useful as long as your shell doesn't support utf8 encoded characters.
In the example above, for example, I piped the output to another file forcing its writing in utf8.



=head1 SEE ALSO

If you also want the translation, check out the Lingua::AR::Db module.
You may find more info about ArabTeX encoding at ftp://ftp.informatik.uni-stuttgart.de/pub/arabtex/arabtex.htm


=head1 TODO

=over

=item Add function which returns the Arabic form of a translitterated word.

=item Add function which analyzes the arabic word and returns info about it: gender, {gender,number} of person/people it refers to,..

=back

=head1 AUTHOR

Andrea Benazzo, E<lt>andy@slacky.itE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 Andrea Benazzo. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.


=cut
