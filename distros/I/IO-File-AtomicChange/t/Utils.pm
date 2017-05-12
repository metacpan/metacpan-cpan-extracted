package t::Utils;

use strict;
use warnings;
use Carp;

use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(write_and_read
             cleanup_backup list_backup
             stat_mode_owner stat_time
             slurp
           );

use Path::Class;
use lib Path::Class::Dir->new(qw(t lib))->stringify;
use Test::More;

use IO::File::AtomicChange;

sub hok(@) {
    print "hey\n";
}

sub write_and_read {
    my($ctor_arg, $data, $cb) = @_;
    my($target_file, $mode, $opt) = @$ctor_arg;

    my $f = IO::File::AtomicChange->new($target_file, $mode, $opt);
    #my $f = IO::File->new($target_file, $mode);
    $cb->{before_write}->($f) if $cb->{before_write};
    $f->print($_) for @$data;
    $cb->{before_close}->($f) if $cb->{before_close};
    $f->close;

    return slurp($target_file);
}

sub _matched_file {
    my($backup_dir, $basename) = @_;
    return
        sort {$b->basename cmp $a->basename }
        grep {!$_->is_dir && $_->basename =~ /^$basename/}
        Path::Class::Dir->new($backup_dir)->children;
}

sub cleanup_backup {
    my($backup_dir, $basename) = @_;
    map {$_->remove} _matched_file($backup_dir, $basename);
}

sub list_backup {
    my($backup_dir, $basename) = @_;
    return _matched_file($backup_dir, $basename);
}

sub stat_mode_owner {
    return (stat $_[0])[2,4,5]; # mode, uid, gid
}

sub stat_time {
    return (stat $_[0])[9]; # mtime
}

sub slurp {
    open my $fh, '<', $_[0] or Carp::croak $!;
    my $buf = do { local $/; <$fh> };
    close $fh;
    return $buf;
}

1;

__END__

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8
# End:

# vi: set ts=4 sw=4 sts=0 :
