package # hide from cpan =)
    HTC_Utils;
use base 'Exporter';
use File::Spec;
@EXPORT_OK = qw($cache $cache_lock $tdir &cdir &create_cache &remove_cache);

$cache = File::Spec->catdir(qw(t cache));
$cache_lock = File::Spec->catdir(qw(t cache lock));
$tdir  = File::Spec->catdir(qw(t templates));

sub cdir { File::Spec->catdir(@_) }

sub create_cache {
    my ($dir) = @_;
    my $cache = File::Spec->catdir('t', $dir);
    mkdir $cache;
    return $cache;
}

sub remove_cache {
    my ($dir) = @_;
    $dir ||= 'cache';
    my $cache = $dir;
    my $cache_lock = File::Spec->catdir($dir, 'lock');
    unlink $cache_lock;
    rmdir $cache;
}
1;
