package Lingua::FreeLing3::Word::Analysis;

use utf8;
use warnings;
use strict;

use Lingua::FreeLing3;
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Word;

use Carp;
use parent -norequire, 'Lingua::FreeLing3::Bindings::analysis';

our $VERSION = '0.02';

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::Word::Analysis - Interface to FreeLing3 Analysis object

=head1 SYNOPSIS

   use Lingua::FreeLing3::Word::Analysis;

   # obtain the list of analysis
   my $list_of_analysis = $word->analysis;

   # create empty analysis object
   my $analysis = Lingua::FreeLing3::Analysis->new();

   my $data = $analysis->as_hash;

=head1 DESCRIPTION

This module interfaces to the Analysis object from FreeLing3. Usually
you do not need to create this kind of object, unless you are hacking
deep in the FreeLing3 library. The usual usage is to retrieve a list of
possible analysis for a specific word using the C<analysis> method on
L<Lingua::FreeLing3::Word> objects.

=head2 CONSTRUCTOR

=over 4

=item C<new>

At the present moment there is one only (empty) constructor. Returns
an C<Lingua::FreeLing3::Word::Analysis> object.

=back

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    return bless $self => $class #amen
}

sub _new_from_binding {
    my ($class, $analysis) = @_;
    return bless $analysis => $class #amen
}

=head2 ACESSORS

These methods let you query an Analysis object:

=over 4

=item C<as_hash>

Retrieve a reference to a hash that includes the analysis lemma,
tag (POS) and probability.

=back

=cut

sub as_hash {
    my $self = shift;
    my $prob = $self->prob;
    return +{
             lemma  => $self->lemma,
             tag    => $self->tag,
             defined($prob) ? (prob   => $prob): ()
            };
}

=head2 ACESSORS/SETTER

These methods let you access an object information or, if you pass any
argument to the method, set that information.

=over 4

=item C<lemma>

Query the current analysis lemma. Supply a string to the method to set
the analysis lemma.

  my $lemma = $analysis->lemma;

=cut

sub lemma {
    my $self = shift;
    if ($_[0]) {
        $self->SUPER::set_lemma(@_);
    } else {
        my $l = $self->SUPER::get_lemma;
        utf8::decode($l);
        return $l;
    }
}

=item C<tag>

Query the current analysis tag (POS). Supply a string to the method
to set the analysis tag.

  my $pos = $analysis->tag;

=cut

sub tag {
    my $self = shift;
    if ($_[0]) {
        $self->SUPER::set_tag(@_);
    } else {
        $self->SUPER::get_tag;
    }
}

=item C<prob>

Query the current analysis probability. Note that some analysis might
not have a probability associated. In that case, the method returns
undef (not zero). Therefore, you should not use this method in boolean
context but rather in definedness context.

  my $prob = $analysis->prob;

=cut

sub prob {
    my $self = shift;
    if ($_[0]) {
        $self->SUPER::set_prob(Lingua::FreeLing3::_validate_prob($_[0] => 0));
    }
    elsif ($self->SUPER::has_prob) {
        $self->SUPER::get_prob;
    }
    else {
        return undef;
    }
}


=item C<retokenizable>

This method lets you query if the word can be retokenizable. That is,
if there is another way to represent this string. A common example for
the Portuguese language is "da" that is also represented by "de a".

Returns undef if the analysis is not retokenizable. Otherwise, return
a list of L<Lingua::FreeLing3::Word> objects.

  my $list_of_tokens = $analysis->retokenizable;

=cut

sub retokenizable {
    my $self = shift;
    if ($_[0]) {
        if (Lingua::FreeLing3::_is_word_list($_[0])) {
            my $list = shift;
            $self->SUPER::set_retokenizable($list);
        } else {
            carp "Error: Tried to set retokenizable with wrong type of argument";
        }
    } else {
        if ($self->SUPER::is_retokenizable) {
            my $words = $self->SUPER::get_retokenizable();
            for (@$words) {
                $_ = Lingua::FreeLing3::Word->_new_from_binding($_);
            }
            return $words;
        } else {
            return undef;
        }
    }
}


# # XXX TODO = No idea how to make this work...
# #       prototype: analysis_get_short_parole(self,std::string const &);
# # *get_short_parole = *Lingua::FreeLing3::Bindingsc::analysis_get_short_parole;
# sub get_short_parole {
#     my $self = shift;
#     my $x = $self->SUPER::analysis_get_short_parole();
#     use Data::Dumper;
#     print STDERR Dumper($x);
# }

# XXX TODO = 
# *get_senses_string = *Lingua::FreeLing3::Bindingsc::analysis_get_senses_string;
# sub senses {
#     my $self = shift;
#     return $self->{analysis}->get_senses_string;
#}


1;

__END__

=back

=head1 SEE ALSO

Lingua::FreeLing3(3) for the documentation table of contents. The
freeling library for extra information, or perl(1) itself.

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

Jorge Cunha Mendes E<lt>jorgecunhamendes@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Projecto Natura

=cut
