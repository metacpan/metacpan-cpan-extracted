use Test::More tests => 5;
BEGIN { use_ok('HTML::Template::Compiled') };
HTML::Template::Compiled->ExpireTime(1);
use lib 't';
use HTC_Utils qw($tdir &cdir &create_cache &remove_cache);
my $cache_dir = "cache05";
$cache_dir = create_cache($cache_dir);

my $filter = sub {
	for (${$_[0]}) {
		s#\{\{\{ nomen est (\w+) \}\}\}#<tmpl_var name="$1">#gi;
		s#\{\{\{ iterate over (\w+) \}\}\}#<tmpl_loop name="$1">#gi;
		s#\{\{\{ end of iterate \}\}\}#</tmpl_loop>#gi;
		s#\{\{\{ occupy (\S+) \}\}\}#<tmpl_include $1>#gi;
	};
};

my $f1 = File::Spec->catfile(qw/ t templates filter.htc /);
my $f2 = File::Spec->catfile(qw/ t templates filter_included.htc /);
chmod 0644, $f1;
chmod 0644, $f2;

my $filters = {
	'sub' => $filter,
};
test($filter, 1);
test([$filters], 2);
test($filters, 3);
test($filters, 4);

sub test {
	my ($f, $i) = @_;
	# test filter
    utime(time, time, $f2) or die $!;
    unless ($i == 4) {
        utime(time, time, $f1) or die $!;
    }
    sleep 1;
    my $htc;
    {
        local $SIG{__WARN__} = sub {
            unless ($_[0] =~ m/subroutine .* redefined/i) {
                print STDERR "warning: @_\n";
            }
        };
        $htc = HTML::Template::Compiled->new(
            path => 't/templates',
            filename => 'filter.htc',
            filter => $f,
            file_cache_dir => $cache_dir,
            file_cache => 1,
        );
    }
	$htc->param(
		omen => 'Caesar',
		list => [
			{ bellum => 'Gallicum' },
			{ bellum => 'Gallicum I' },
			{ bellum => 'Gallicum II' },
		],
	);
	my $exp = <<'EOM';
Name: Caesar
War: Bellum Gallicum
War: Bellum Gallicum I
War: Bellum Gallicum II

Included Name: Caesar

EOM
	my $out = $htc->output();
	cmp_ok($out, 'eq', $exp, "filter $i");
	$htc->clear_cache() if $i < 3;
    #print "\n($out)\n($exp)\n";
    delete $INC{'HTML/Template/Compiled/Filter.pm'};
    no strict 'refs';
    undef *{ 'HTML::Template::Compiled::Filter::filter' };
}

HTML::Template::Compiled->clear_filecache($cache_dir);
remove_cache($cache_dir);


__END__
