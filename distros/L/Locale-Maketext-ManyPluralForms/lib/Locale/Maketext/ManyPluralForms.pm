package Locale::Maketext::ManyPluralForms;
# ABSTRACT: internationalisation with many plural forms
use strict;
use warnings;

our $VERSION = '0.04';

require Locale::Maketext::Lexicon;

use parent 'Locale::Maketext';

sub import {
    shift;
    return Locale::Maketext::Lexicon->import(@_);
}

sub plural {
    my ($self, $num, @strings) = @_;
    unless (defined $num) {
        warn 'Use of uninitialized value $num in ' . ref($self) . " with params: '" . join(";", @strings) . "'";
        $num = 0;
    }
    unless ($self->{_plural}) {
        my $class = ref $self;
        no strict 'refs';    ## no critic
        my $header = ${"${class}::Lexicon"}{"__Plural-Forms"};
        if ($header) {
            $header =~ s/^.*plural\s*=\s*([^;]+);.*$/$1/;
            $header =~ s/\[_([0-9]+)\]/%$1/g;
            die "Invalid expression for plural: $header" if $header =~ /\$|n\s*\(|[A-Za-mo-z]|nn/;
            $header =~ s/n/\$_[0]/g;
            eval "\$self->{_plural} = sub { return $header }";    ## no critic (ProhibitStringyEval RequireCheckingReturnValueOfEval)
        } else {
            $self->{_plural} = sub { return $_[0] != 1 };
        }
    }
    my $pos = $self->{_plural}($num);
    $pos = $#strings if $pos > $#strings;
    return sprintf $strings[$pos], $num;
}

1;

__END__

=head1 NAME

Locale::Maketext::ManyPluralForms

=head1 SYNOPSIS

    use Locale::Maketext::ManyPluralForms {'*' => ['Gettext' => 'i18n/*.po']};
    my $lh = Locale::Maketext::ManyPluralForms->get_handle('en');
    $lh->maketext("Hello");

=head1 DESCRIPTION

The implementation supporting internationalisation with many plural forms
using Plural-Forms header from .po file to add plural method to Locale::Maketext based class.
As described there L<http://www.perlmonks.org/index.pl?node_id=898687>.

=head1 METHODS

=cut

=head2 Locale::Maketext::ManyPluralForms->import({'*' => ['Gettext' => 'i18n/*.po']})

This method to specify languages.

=cut

=head2 $self->plural($num, @strings)

This method handles plural forms. You can invoke it using Locale::Maketext's
bracket notation, like "[plural,_1,string1,string2,...]". Depending on value of
I<$num> and language function returns one of the strings. If string contain %d
it will be replaced with I<$num> value.

=cut

=head1 SEE ALSO

L<Locale::Maketext>,
L<Locale::Maketext::Lexicon>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 binary.com

=cut
