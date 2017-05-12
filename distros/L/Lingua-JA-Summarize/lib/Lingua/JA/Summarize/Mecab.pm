package Lingua::JA::Summarize::Mecab;

use strict;
use warnings;

use Lingua::JA::Summarize;

sub new {
    my ($proto, $ljs, $srcfile) = @_;
    my $klass = ref $proto || $proto;
    
    # open mecab
    my $mecab = $ljs->mecab;
    my $def_cost =
        $ljs->default_cost * Lingua::JA::Summarize::DEFAULT_COST_FACTOR();
    my $mecab_cmd = join(' ', (
        $mecab,
        q(--node-format="%m\t%pn\t%pw\t%H\n"),
        sprintf(
            q(--unk-format="%%m\t%d\t%d\tUnkType\n"), $def_cost, $def_cost),
        q(--bos-format="\n"),
        q(--eos-format="\n"),
        $srcfile,
    ));
    open my $fh, '-|', $mecab_cmd
        or croak("failed to call mecab ($mecab): $!");
    my $self = bless {
        fh => $fh,
    }, $klass;
    $self;
}

sub DESTROY {
    my $self = shift;
    $self->{fh}->close;
}

sub getline {
    my $self = shift;
    $self->{fh}->getline;
}

1;
__END__

=head1 NAME

Lingua::JA::Summarize::Mecab - mecab wrapper for C<Lingua::JA::Summarize>

=head1 METHODS

=head2 new

=head2 getline

=head1 AUTHOR

Kazuho Oku E<lt>kazuhooku ___at___ gmail.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2006-2008  Cybozu Labs, Inc.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.7 or, at your option, any later version of Perl 5 you may have available.

=cut
