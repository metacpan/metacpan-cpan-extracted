package Lingua::FreeLing3::Word;

use warnings;
use strict;

use utf8;
use Lingua::FreeLing3;
use Lingua::FreeLing3::Bindings;
use Lingua::FreeLing3::Word::Analysis;

use parent -norequire, 'Lingua::FreeLing3::Bindings::word';

our $VERSION = "0.04";

# XXX - Missing
# *add_analysis = *Lingua::FreeLing3::Bindingsc::word_add_analysis;
# *set_analysis = *Lingua::FreeLing3::Bindingsc::word_set_analysis;
# *found_in_dict = *Lingua::FreeLing3::Bindingsc::word_found_in_dict;

# *get_n_selected = *Lingua::FreeLing3::Bindingsc::word_get_n_selected;
# *get_n_unselected = *Lingua::FreeLing3::Bindingsc::word_get_n_unselected;
# *get_n_words_mw = *Lingua::FreeLing3::Bindingsc::word_get_n_words_mw;
# *selected_begin = *Lingua::FreeLing3::Bindingsc::word_selected_begin;
# *selected_end = *Lingua::FreeLing3::Bindingsc::word_selected_end;
# *unselected_begin = *Lingua::FreeLing3::Bindingsc::word_unselected_begin;
# *unselected_end = *Lingua::FreeLing3::Bindingsc::word_unselected_end;
# *get_senses_string = *Lingua::FreeLing3::Bindingsc::word_get_senses_string;
# *get_span_start = *Lingua::FreeLing3::Bindingsc::word_get_span_start;
# *get_span_finish = *Lingua::FreeLing3::Bindingsc::word_get_span_finish;
# *set_found_in_dict = *Lingua::FreeLing3::Bindingsc::word_set_found_in_dict;
# *has_retokenizable = *Lingua::FreeLing3::Bindingsc::word_has_retokenizable;
# *set_span = *Lingua::FreeLing3::Bindingsc::word_set_span;
# *find_tag_match = *Lingua::FreeLing3::Bindingsc::word_find_tag_match;
# *copy_analysis = *Lingua::FreeLing3::Bindingsc::word_copy_analysis;
# *select_analysis = *Lingua::FreeLing3::Bindingsc::word_select_analysis;
# *unselect_analysis = *Lingua::FreeLing3::Bindingsc::word_unselect_analysis;
# *get_n_analysis = *Lingua::FreeLing3::Bindingsc::word_get_n_analysis;
# *unselect_all_analysis = *Lingua::FreeLing3::Bindingsc::word_unselect_all_analysis;
# *select_all_analysis = *Lingua::FreeLing3::Bindingsc::word_select_all_analysis;
# *analysis_begin = *Lingua::FreeLing3::Bindingsc::word_analysis_begin;
# *analysis_end = *Lingua::FreeLing3::Bindingsc::word_analysis_end;

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::Word - Interface to FreeLing3 Word object

=head1 SYNOPSIS

   use Lingua::FreeLing3::Word;

   my $empty_word = Lingua::FreeLing3::Word->new;
   my $hello_word = Lingua::FreeLing3::Word->new('hello');

=head1 DESCRIPTION

Interface to the FreeLing3 word object.

=head2 C<new>

The C<new> constructor returns a new C<Lingua::FreeLing3::Word>
object. If a parameter is passed, it is interpreted as the word form,
and it is automatically set. Otherwise, an empty word object is
returned.

=cut

sub new {
    my $class = shift;
    my $word = $class->SUPER::new(@_);
    return bless $word => $class #amen
}

sub _new_from_binding {
    my ($class, $word) = @_;
    return bless $word => $class #amen
}

=head2 C<as_hash>

Returns a reference to a hash with the form, lemma and tag (POS) of
the word.

=cut

sub as_hash {
    my $self = shift;
    return +{
             form    => $self->form,
             lc_form => $self->lc_form,
             lemma   => $self->lemma,
             tag     => $self->tag,
            };
}

=head2 C<lemma>

Returns the word C<lemma>, if set. Note that this value can't be set
directly. You can create word analysis, associate them to the word,
and then select the desired analysis (setting up the lemma value).

  my $word_lemma = $word->lemma;

=cut

sub lemma {
    my $l = $_[0]->SUPER::get_lemma;
    utf8::decode($l);
    return $l
}

=head2 C<tag>

Returns the word C<tag> (POS), if set. Again, note that this value
can't be set directly. You can create word analysis, associate them to
the word, and then select the desired analysis (setting up the tag
value).

  my $word_pos = $word->tag;

=cut

sub tag { $_[0]->SUPER::get_tag }

=head2 C<analysis>

Returns a list of possible analysis. You can pass an extra option
C<FeatureStructure> to obtain the analysis as a list of hashes (list
of feature structures), instead of L<Lingua::FreeLing3::Word::Analysis>
objects.

  my $list = $word->analysis(FeatureStructure => 1);

B<TODO:> it is missing the option to add an analysis, or set the full
set at once.

=cut

sub analysis {
    my ($self, %ops) = @_;
    my $analysis_list = $self->SUPER::get_analysis;
    for (@$analysis_list) {
        $_ = Lingua::FreeLing3::Word::Analysis->_new_from_binding($_);
        if (defined($ops{FeatureStructure})) {
            $_ = $_->as_hash;
        }
    }
    return $analysis_list;
}

=head2 C<form>

Set/retrieve word form.

   my $word_form = $word->form;

=cut

sub form {
    my $self = shift;
    if ($_[0]) {
        $self->SUPER::set_form(shift @_)
    } else {
        my $word = $self->SUPER::get_form;
        utf8::decode($word);
        return $word;
    }
}

=head2 C<lc_form>

Retrieve lowercase word form.

   my $lc_form = $word->lc_form;

=cut

sub lc_form {
    my $word = $_[0]->SUPER::get_lc_form;
    utf8::decode($word);
    return $word;
}

=head2 C<is_multiword>

Returns a true value is the word is a multiword.

=cut

sub is_multiword { $_[0]->SUPER::is_multiword }

=head2 C<get_mw_words>

For a multiword word, this method returns an array of its constituent
words in array context. In scalar context returns the multiword as a
string (words concatenated by a whitespace).

Returns undef if word is not a multiword.

=cut

sub get_mw_words {
    my $self = shift;
    return undef unless $self->is_multiword;

    my $wl = $self->SUPER::get_words_mw->elements;

    if (wantarray) {
        return map {
            $_->ACQUIRE();
            Lingua::FreeLing3::Word->_new_from_binding($_)
          } @$wl
    } else {
        return join(" ", map {
            my $w = $_->get_form();
            utf8::decode($w);
            $w
        } @$wl)
    }
}

# =head2 C<in_dict>

# Returns true if the word was found in the dictionary, false otherwise.
# B<FIXME:> at the moment this method is always returning true.

# =cut

# sub in_dict { $_[0]->SUPER::found_in_dict }

=head1 TODO

There are a lot of methods to interface with the Word object that are
currently not implemented. They should be made available as soon as
there is time.

=cut

1;

__END__

=head1 SEE ALSO

Lingua::FreeLing3(3) for the documentation table of contents. The
freeling library for extra information, or perl(1) itself.

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2012 by Projecto Natura

=cut


