#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Benchmark qw/ timethese cmpthese /;
use FindBin qw/ $RealBin /;
chdir "$RealBin/..";
#use Devel::Size qw(size total_size);
my $count = 0;
mkdir "cache";
mkdir "cache/htc";
mkdir "cache/htcc";
mkdir "cache/hte";
mkdir "cache/htpl";
mkdir "cache/jit";
my %use = (
	'HTML::Template'           => 0,
    'HTML::Template::Pro'      => 0,
	'HTML::Template::Compiled' => 0,
	'HTML::Template::Pluggable' => 0,
	'HTML::Template::Expr' => 0,
	'HTML::Template::Compiled::Classic' => 0,
#	'HTML::Template::JIT'      => 0,
	'Template'                 => 0,
    'Template::Alloy'                 => 0,
    'Template::HTML'           => 0,
    'Template::AutoFilter'     => 0,
    'Template::Like'           => 0,
	'CGI::Ex::Template'        => 0,
	# not yet
	'Text::ScriptTemplate'     => 0,
    'Text::Xslate'             => 0,
);
for my $key (sort keys %use) {
	eval "require $key";
	$use{$key} = 1 unless $@;
	my $version = $use{$key} ? $key->VERSION : "-";
    printf "using %35s %s\n", $key, $version;
}
HTML::Template::Compiled->clear_filecache("cache/htc");
HTML::Template::Compiled->clear_filecache("cache/htcc");
my $debug = 0;
$ENV{'HTML_TEMPLATE_ROOT'} = "examples";
my $FILE_CACHE     = 0;
my $MEM_CACHE      = 1;
my $LOOP_CONTEXT   = 1;
my $GLOBAL_VARS    = 0;
my $CASE_SENSITIVE = 1;
my $default_escape = 0;
my $template_size  = 1;
my $bench          = 'timethese';
GetOptions(
    "file-cache=i" => \$FILE_CACHE,
    "mem-cache=i" => \$MEM_CACHE,
    "loop-context=i" => \$LOOP_CONTEXT,
    "global-vars=i" => \$GLOBAL_VARS,
    "case-sensitive=i" => \$CASE_SENSITIVE,
    "default-escape=i" => \$default_escape,
    "template-size=i" => \$template_size,
    "bench=s" => \$bench,
);
my $iterations = shift;
my $ht_file = 'test.htc';
my $htcc_file = $ht_file . 'c';
my $tt_file = "test.tt";
my $tst_file = "test.tst";
my $xslfile = "test.xslate";
$template_size =~ tr/0-9//cd;
if ($template_size > 1) {
    for my $file ($ht_file, $htcc_file, $tt_file, $tst_file, $xslfile) {
        open my $fh, "<", "examples/$file" or die "examples/$file: $!";
        my $data = do { local $/; <$fh> };
        my $new_file = "$file.n$template_size";
        open my $out, ">", "examples/$new_file" or die $!;
        print $out $data x $template_size;
        $file = $new_file;
    }
}

print "running with:
--file-cache $FILE_CACHE --mem-cache $MEM_CACHE --loop-context $LOOP_CONTEXT "
. "--global-vars $GLOBAL_VARS --case-sensitive $CASE_SENSITIVE "
. "--default-escape $default_escape --template-size=$template_size
";

my $STDOUT = 0;
sub new_htc {
	my $t1 = HTML::Template::Compiled->new_file( $ht_file,
		#path => 'examples',
		case_sensitive => $CASE_SENSITIVE, # slow down
		loop_context_vars => $LOOP_CONTEXT,
        $default_escape ? (default_escape => 'HTML') : (),
		debug => $debug,
		# note that you have to create the cachedir
		# first, otherwise it will run without cache
#        cache_dir => ($FILE_CACHE ? "cache/htc" : undef),
        file_cache_dir => ($FILE_CACHE ? "cache/htc" : undef),
        file_cache => ($FILE_CACHE ? 1 : undef),

        cache => $MEM_CACHE,
		out_fh => $STDOUT ? 1 : 0,
        global_vars => $GLOBAL_VARS,
        tagstyle => [qw(-asp -comment)],
		expire_time => 1000,
	);
	return $t1;
}

sub new_htcc {
	my $t1 = HTML::Template::Compiled::Classic->new_file( $htcc_file,
		#path => 'examples',
		case_sensitive => $CASE_SENSITIVE, # slow down
		loop_context_vars => $LOOP_CONTEXT,
        $default_escape ? (default_escape => 'HTML') : (),
		debug => $debug,
		# note that you have to create the cachedir
		# first, otherwise it will run without cache
        cache_dir => ($FILE_CACHE ? "cache/htcc" : undef),
        cache => $MEM_CACHE,
		out_fh => $STDOUT ? 1 : 0,
        global_vars => $GLOBAL_VARS,
        debug => 0,
        tagstyle => [qw(-asp -comment)],
		expire_time => 1000,
        #debug => 1,
	);
	return $t1;
}

sub new_tst {
	my $t = Text::ScriptTemplate->new();
	$t->load("examples/$tst_file");
	#my $size = total_size($t1);
	#print "size htc = $size\n";
	return $t;
}

sub new_htp {
	my $t2 = HTML::Template::Pro->new(
		case_sensitive => $CASE_SENSITIVE,
		loop_context_vars => $LOOP_CONTEXT,
        $default_escape ? (default_escape => 'HTML') : (),
		#path => 'examples',
		filename => $ht_file,
#		cache => $MEM_CACHE,
#        $FILE_CACHE ?
#        (file_cache => $FILE_CACHE,
#        file_cache_dir => 'cache/ht') : (),
        global_vars => $GLOBAL_VARS,
#        die_on_bad_params => 0,
	);
	return $t2;
}

sub new_ht {
	my $t2 = HTML::Template->new(
		case_sensitive => $CASE_SENSITIVE,
		loop_context_vars => $LOOP_CONTEXT,
        $default_escape ? (default_escape => 'HTML') : (),
		#path => 'examples',
		filename => $ht_file,
		cache => $MEM_CACHE,
        $FILE_CACHE ?
        (file_cache => $FILE_CACHE,
        file_cache_dir => 'cache/ht') : (),
        global_vars => $GLOBAL_VARS,
        die_on_bad_params => 0,
		blind_cache => 1,
	);
	return $t2;
}
sub new_hte {
	my $t2 = HTML::Template::Expr->new(
		case_sensitive => $CASE_SENSITIVE,
		loop_context_vars => $LOOP_CONTEXT,
        $default_escape ? (default_escape => 'HTML') : (),
		#path => 'examples',
		filename => $ht_file,
		cache => $MEM_CACHE,
        $FILE_CACHE ?
        (file_cache => $FILE_CACHE,
        file_cache_dir => 'cache/hte') : (),
        global_vars => $GLOBAL_VARS,
        die_on_bad_params => 0,
	);
	return $t2;
}
sub new_htpl {
	my $t2 = HTML::Template::Pluggable->new(
		case_sensitive => $CASE_SENSITIVE,
		loop_context_vars => $LOOP_CONTEXT,
        $default_escape ? (default_escape => 'HTML') : (),
		#path => 'examples',
		filename => $ht_file,
		cache => $MEM_CACHE,
        $FILE_CACHE ?
        (file_cache => $FILE_CACHE,
        file_cache_dir => 'cache/htpl') : (),
        global_vars => $GLOBAL_VARS,
        die_on_bad_params => 0,
	);
	return $t2;
}

sub new_htj {
	my $t2 = HTML::Template::JIT->new(
		loop_context_vars => 1,
        $default_escape ? (default_escape => 'HTML') : (),
		#path => 'examples',
		filename => $ht_file,
		cache => 1,
		jit_path => 'cache/jit',
        #global_vars => 1,
	);
	return $t2;
}

sub new_tl {
	my $tt= Template::Like->new(
    );

#        $FILE_CACHE
#            ? (
#                COMPILE_EXT => '.ttc',
#                COMPILE_DIR => 'cache/tt',
#            )
#            : (),
#        $MEM_CACHE
#            ? ()
#            : (CACHE_SIZE => 0),
#		INCLUDE_PATH => 'examples',

	#my $size = total_size($tt);
	#print "size tt  = $size\n";
	return $tt;
}

sub new_tt {
	my $tt= Template->new(
        $FILE_CACHE
            ? (
                COMPILE_EXT => '.ttc',
                COMPILE_DIR => 'cache/tt',
            )
            : (),
        $MEM_CACHE
            ? ()
            : (CACHE_SIZE => 0),
		INCLUDE_PATH => 'examples',
	);
	#my $size = total_size($tt);
	#print "size tt  = $size\n";
	return $tt;
}

sub new_ta {
    my $tt = Template::Alloy->new(
        $FILE_CACHE
            ? (
                COMPILE_EXT => '.ttc',
                COMPILE_DIR => 'cache/tt',
            )
            : (),
        $MEM_CACHE
            ? ()
            : (CACHE_SIZE => 0),
        INCLUDE_PATH => 'examples',
    );
	#my $size = total_size($tt);
	#print "size tt  = $size\n";
    return $tt;
}

sub new_ttaf {
	my $tt= Template::AutoFilter->new(
        $FILE_CACHE
            ? (
                COMPILE_EXT => '.ttc',
                COMPILE_DIR => 'cache/tt',
            )
            : (),
        $MEM_CACHE
            ? ()
            : (CACHE_SIZE => 0),
		INCLUDE_PATH => 'examples',
	);
	#my $size = total_size($tt);
	#print "size tt  = $size\n";
	return $tt;
}

sub new_tth {
	my $tt= Template::HTML->new(
        $FILE_CACHE
            ? (
                COMPILE_EXT => '.ttc',
                COMPILE_DIR => 'cache/tt',
            )
            : (),
        $MEM_CACHE
            ? ()
            : (CACHE_SIZE => 0),
		INCLUDE_PATH => 'examples',
	);
	#my $size = total_size($tt);
	#print "size tt  = $size\n";
	return $tt;
}

sub new_xslate {
    # Text::Xslate has no file caching
    my $t = Text::Xslate->new(
        $MEM_CACHE ? (cache => 2, cache_dir => "cache/xslate") : (),
        path => 'examples',
        syntax => 'TTerse',
    );
    return $t;
}

sub new_cet {
	my $tt= CGI::Ex::Template->new(
        $FILE_CACHE
            ? (
                COMPILE_EXT => '.ttc',
                COMPILE_DIR => 'cache/tt',
            )
            : (),
        $MEM_CACHE
            ? ()
            : (CACHE_SIZE => 0),
		INCLUDE_PATH => 'examples',
	);
	#my $size = total_size($tt);
	#print "size tt  = $size\n";
	return $tt;
}

sub new_st {
	my $st = Text::ScriptTemplate->new;
	$st->load("examples/template.st");
}

my %params = (
	name => '',
	loopa => [{a=>3},{a=>4},{a=>5}],
	#a => [qw(b c d)],
	loopb => [{ inner => 23 }],
	c => [
	 {
		 d=>[({F=>11},{F=>22}, {F=>33})]
	 },
	{
		d=>[({F=>44}, {F=>55}, {F=>66})]
	}
	],
	if2 => 1,
	if3 => 0,
	blubber => "html <test>",
);
open OUT, ">>/dev/null";
#open OUT, ">&STDOUT";

sub output {
	my $t = shift;
	return unless defined $t;
	$t->param(%params);
    if ($STDOUT) {
        my $out;
        if ($t=~m/Compiled/) {
            $out = $t->output(\*OUT);
        }
        else {
            $out = $t->output;
        }
        print OUT $out;
    }
    else {
        my $out = $t->output();
    }
	#print "output():$out\n";
	#my $size = total_size($t);
	#print "size $t = $size\n";
}

sub output_tst {
	my $t = shift;
	return unless defined $t;
	$t->setq(%params,tmpl=>$t);
	my $out = $t->fill;
	#print "output_tst():$out\n";
    if ($STDOUT) {
        print OUT $out;
    }
}
sub output_tl {
	my $t = shift;
	return unless defined $t;
    chdir 'examples';
	my $filett = $tt_file;
    if ($STDOUT) {
        $t->process($filett, \%params, \*OUT) or die $t->error();
    }
    else {
        my $out;
        $t->process($filett, \%params, \$out) or die $t->error();
    }
	#my $size = total_size($t);
	#print "size $t = $size\n";
	#my $out = $t->output;
	#print "\nOUT: $out";
    chdir '..';
}

sub output_tt {
	my $t = shift;
	return unless defined $t;
	my $filett = $tt_file;
	#$t->process($filett, \%params, \*OUT);
    if ($STDOUT) {
        $t->process($filett, \%params, \*OUT) or die $t->error();
    }
    else {
        my $out;
        $t->process($filett, \%params, \$out) or die $t->error();
    }
	#my $size = total_size($t);
	#print "size $t = $size\n";
	#print $t->{code} if exists $t->{code};
    #my $out = $t->output;
    #print "\nOUT: $out";
}

sub output_ttaf {
	my $t = shift;
	return unless defined $t;
	my $filett = $tt_file;
	#$t->process($filett, \%params, \*OUT);
    if ($STDOUT) {
        $t->process($filett, \%params, \*OUT) or die $t->error();
    }
    else {
        my $out;
        $t->process($filett, \%params, \$out) or die $t->error();
    }
	#my $size = total_size($t);
	#print "size $t = $size\n";
	#print $t->{code} if exists $t->{code};
    #my $out = $t->output;
    #print "\nOUT: $out";
}

sub output_xslate {
	my $t = shift;
	return unless defined $t;
	my $filett = $tt_file;
	#$t->process($filett, \%params, \*OUT);
#	$t->process($filett, \%params, \*OUT) or die $t->error();
	#my $size = total_size($t);
	#print "size $t = $size\n";
	#print $t->{code} if exists $t->{code};
    my $out = $t->render($xslfile, \%params);
    #my $out = $t->output;
    if ($STDOUT) {
        print OUT $out;
    }
}

my $global_htc = $use{'HTML::Template::Compiled'} ? new_htc : undef;
my $global_htcc = $use{'HTML::Template::Compiled::Classic'} ? new_htcc : undef;
my $global_ht = $use{'HTML::Template'} ? new_ht : undef;
my $global_htp = $use{'HTML::Template::Pro'} ? new_htp : undef;
my $global_htpl = $use{'HTML::Template::Pluggable'} ? new_htpl : undef;
my $global_htj = $use{'HTML::Template::JIT'} ? new_htj : undef;
my $global_tt = $use{'Template'} ? new_tt : undef;
my $global_ta = $use{'Template::Alloy'} ? new_ta : undef;
my $global_ttaf = $use{'Template::AutoFilter'} ? new_ttaf : undef;
my $global_tth = $use{'Template::HTML'} ? new_tth : undef;
my $global_xslate = $use{'Text::Xslate'} ? new_xslate : undef;
my $global_tl = $use{'Template::Like'} ? new_tl : undef;
my $global_cet = $use{'CGI::Ex::Template'} ? new_cet : undef;
my $global_tst = $use{'Text::ScriptTemplate'} ? new_tst : undef;
if(1) {
my %args = (
       $use{'HTML::Template::Compiled'} ? (
            # deactivate memory cache
            #new_htc_w_clear_cache => sub {my $t = new_htc();$t->clear_cache},
            # normal, with memory cache
            # new_htc => sub {my $t = new_htc()},
            #output_htc => sub {output($global_htc)},
            all_htc => sub {my $t = new_htc();output($t)},
        ) : (),
        $use{'HTML::Template::Compiled::Classic'} ? (
            # deactivate memory cache
            #new_htc_w_clear_cache => sub {my $t = new_htc();$t->clear_cache},
            # normal, with memory cache
            # new_htcc => sub {my $t = new_htcc()},
            #output_htc => sub {output($global_htc)},
            all_htcc => sub {my $t = new_htcc();output($t)},
        ) : (),
		$use{'HTML::Template'} ? (
            # new_ht => sub {my $t = new_ht()},
			#output_ht => sub {output($global_ht)},
						all_ht => sub {my $t = new_ht();output($t)},
        ) : (),
		$use{'HTML::Template::Pro'} ? (
            # new_htp => sub {my $t = new_htpl()},
			#output_htp => sub {output($global_htp)},
						all_htp => sub {my $t = new_htp();output($t)},
        ) : (),
		$use{'HTML::Template::Pluggable'} ? (
            # new_htpl => sub {my $t = new_htpl()},
			#output_htpl => sub {output($global_htpl)},
						all_htpl => sub {my $t = new_htpl();output($t)},
        ) : (),
        $use{'HTML::Template::Expr'} && !$FILE_CACHE ? (
            # new_hte => sub {my $t = new_hte()},
            #output_hte => sub {output($global_hte)},
            all_hte => sub {my $t = new_hte();output($t)},
        ) : (),
        $use{'HTML::Template::JIT'} ? (
					#new_htj => sub {my $t = new_htj();},
					#output_htj => sub {output($global_htj)},
						all_htj => sub {my $t = new_htj();output($t)},
        ) : (),
        $use{'Template'} ? (
            #new_tt => sub {my $t = new_tt();},
            #output_tt => sub {output_tt($global_tt)},
            process_tt => sub {output_tt($global_tt)},
            $MEM_CACHE
                ? ()
                : (all_tt_new_object => sub {my $t = new_tt();output_tt($t)}),
        ): (),
        $use{'Template::Alloy'} ? (
            #new_tt => sub {my $t = new_tt();},
            #output_tt => sub {output_tt($global_tt)},
            process_ta => sub {output_tt($global_ta)},
            $MEM_CACHE
                ? ()
                : (all_ta_new_object => sub {my $t = new_ta();output_tt($t)}),
        ): (),
        $use{'Template::AutoFilter'} ? (
            #new_ttaf => sub {my $t = new_ttaf();},
            #output_ttaf => sub {output_ttaf($global_ttaf)},
            process_ttaf => sub {output_ttaf($global_ttaf)},
            $MEM_CACHE
                ? ()
                : (all_ttaf_new_object => sub {my $t = new_ttaf();output_ttaf($t)}),
        ): (),
        $use{'Template::HTML'} ? (
            #new_tt => sub {my $t = new_tt();},
            #output_tt => sub {output_tt($global_tt)},
            process_tth => sub {output_tt($global_tth)},
            $MEM_CACHE
                ? ()
                : (all_tth_new_object => sub {my $t = new_tth();output_tt($t)}),
        ): (),
        $use{'Text::Xslate'} ? (
            #new_tt => sub {my $t = new_tt();},
            #output_tt => sub {output_tt($global_tt)},
            process_xslate => sub {output_xslate($global_xslate)},
            $MEM_CACHE
                ? ()
                : (all_xslate_new_object => sub {my $t = new_xslate();output_xslate($t)}),
        ): (),
        $use{'Template::Like'} ? (
            process_tl => sub {output_tl($global_tl)},
        ): (),
        $use{'CGI::Ex::Template'} ? (
            #new_tt => sub {my $t = new_tt();},
            #output_tt => sub {output_tt($global_tt)},
            process_cet => sub {output_tt($global_cet)},
            $MEM_CACHE
                ? ()
                : (all_cet_new_object => sub {my $t = new_cet();output_tt($t)}),
        ): (),
        $use{'Text::ScriptTemplate'} ? (
					#new_tst => sub {my $t = new_tst();},
                    #output_tst => sub {output_tst($global_tst)},
						all_tst => sub {my $t = new_tst();output_tst($t)},
        ): (),
);
# try to align table correctly also for longer strings
my %args_new;
for my $key (keys %args) {
    my $new_key = sprintf "%21s", $key;
    $args_new{ $new_key } = $args{ $key };
}
if ($bench eq 'timethese') {
    timethese ($iterations||-1, {
        %args_new
 	});
}
elsif ($bench eq 'cmpthese') {
    cmpthese ($iterations||-1, {
        %args_new
 	});
}
}
__END__
