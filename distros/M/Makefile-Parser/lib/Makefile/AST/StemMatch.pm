package Makefile::AST::StemMatch;

use strict;
use warnings;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_ro_accessors(qw{
    pattern target stem dir notdir
});

sub _split_path ($) {
    my ($path) = @_;
    my ($dir, $notdir);
    if ($path =~ m{.*/}) {
        $dir = $&;
        $notdir = $';
    } else {
        $dir = '';
        $notdir = $path;
    }
    return ($dir, $notdir);
}

sub _pat2re ($@) {
    my ($pat, $capture) = @_;
    $pat = quotemeta $pat;
    if ($capture) {
        $pat =~ s/\\\%/(\\S*)/;
    } else {
        $pat =~ s/\\\%/\\S*/;
    }
    $pat;
}

sub new ($$) {
    my $class = ref $_[0] ? ref shift : shift;
    my $opts = shift;
    my $pattern = $opts->{pattern};
    my $target  = $opts->{target};
    my ($dir, $notdir) = _split_path($target);
    my $re = _pat2re($pattern, 1);
    my $stem;
    if ($pattern =~ m{/}) {
        if ($target =~ $re) {
            $stem = $1;
        }
    } else {
        if ($notdir =~ $re) {
            $stem = $1;
        }
    }
    if (defined $stem) {
        return $class->SUPER::new(
            {
                pattern => $pattern,
                target  => $target,
                stem    => $stem,
                dir     => $dir,
                notdir  => $notdir,
            }
        );
    } else {
        return undef;
    }
}

sub subs_stem ($$) {
    my ($self, $other_pat) = @_;
    my $stem = $self->stem;
    $other_pat =~ s/\%/$stem/;
    if ($self->pattern !~ m{/}) {
        $other_pat = $self->dir . $other_pat;
    }
    return $other_pat;
}

1;
