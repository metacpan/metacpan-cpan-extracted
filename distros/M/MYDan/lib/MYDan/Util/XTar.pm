package MYDan::Util::XTar;
use strict;
use warnings;
use Carp;
use Tie::File;

$|++;

my @script = (
    '#!/bin/bash',
    'RUN="$0.run"',
    'export TMP="$RUN.tmp"',
    'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH',
    'SKIP=$((SIZE+1))',
    'dd if=$0 of=$RUN skip=1 bs=1024 count=SIZE || exit 1',
    'dd if=$0 of=$TMP skip=$SKIP bs=1024 || exit 1',
    'chmod +x $RUN',
    '$RUN $@',
    'EXIT=$?',
    'rm $RUN $TMP',
    'exit $EXIT',
);

sub new
{
    my ( $class, %self ) = @_;
    map{ die "$_ undef\n" unless $self{$_} } qw( script package output );
    map{ die "nofile: $self{$_}\n" unless -f $self{$_} } qw( script package );
    bless \%self, ref $class || $class;
}

sub xtar
{
    my $this = shift;
    my ( $s, $p, $o ) = @$this{qw( script package output )};

    my $size = int((stat $s)[7]/1024)+1;
    my $skip = $size +1;
    map{ $_ =~ s/SIZE/$size/g }@script;

    die "tie $o fail: $!!" unless tie my @cont, 'Tie::File', $o;
    @cont = @script;
    untie @cont;

    system "dd if=$s of=$o bs=1024 seek=1 && dd if=$p of=$o seek=$skip bs=1024";
    chmod 0755, $o;
}



1;
__END__
