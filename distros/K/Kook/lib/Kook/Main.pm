###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'uninitialized';   # suppress warning 'Use of uninitialized value'


package Kook::Main;
use Data::Dumper;
use File::Basename;

use Kook;
use Kook::Util ('read_file');
use Kook::Cookbook;
use Kook::Kitchen;

sub new {
    my ($class, $argv, $command) = @_;
    if (! $argv || ! @$argv) {
        my @a = @ARGV;    # how to copy array?
        $argv = \@a;
    }
    $command = basename($0) unless $command;
    my $this = {
        argv    => $argv,
        command => $command,
    };
    return bless $this, $class;
}

sub invoke {
    my ($this) = @_;
    die "invoke(): not implemented yet.";
}

sub main {
    my ($this) = @_;
    die "invoke(): not implemented yet.";
}

sub _load_property_file {
    my ($this, $filename) = @_;
    $filename = $Kook::Config::PROPERTIES_FILENAME unless $filename;
    my $props = {};
    if (-f $filename) {
        my $content = read_file($filename);
        my $ret = eval("# line 1 \"$filename\"\n" . $content);
        if ($ret) {
            my %tmp = (%$props, %$ret);
            $props = \%tmp;
        }
        #map { $props->{$_} = $ret->{$_} } keys %$ret if $ret;
        #@$props { keys %$ret } = values %$ret if $ret;
    }
    return $props;
}


package Kook::MainCommand;
our @ISA = ('Kook::Main');
use Data::Dumper;
use Cwd ('realpath');

use Kook::Util ('repr');

my $optdef_strs = [
    "-h:      help",
    #"--help: help",
    "-V:      version",
    "-D[N]:   debug level (default: 1)",
    "-q:      quiet",
    "-f file: kookbook",
    "-F:      forcedly",
    "-n:      not execute (dry run)",
    "-l:      list public recipes",
    "-L:      list all recipes",
    "-R:      search Kookbook in parent directory recursively",
    "--name=value: property name and value",
    "--name:       property name and value(=True)",
];

sub invoke {
    my ($this) = @_;
    ## parse command-line options
    my $optparser = Kook::Util::CommandOptionParser->new($optdef_strs);
    my ($opts, $longopts, $rests) = $optparser->parse2($this->{argv}, $this->{command});
    #print "*** debug: opts=", Dumper($opts);
    #print "*** debug: longopts=", Dumper($longopts);
    #print "*** debug: rests=", Dumper($rests);
    ## handle options
    if ($opts->{h} || $longopts->{help} == 1) {
        print "$this->{command} - build tool like Make, Rake, Ant, or Cook\n";
        print $optparser->help();
        return 0;
    }
    if ($opts->{V}) {
        print $Kook::VERSION, "\n";
        return 0;
    }
    if ($opts->{q}) { $Kook::Config::VERBOSE = 0; }
    if ($opts->{F}) { $Kook::Config::FORCED  = 1; }
    if ($opts->{n}) { $Kook::Config::NOEXEC  = 1; }
    if ($opts->{D}) {
        my $v = $opts->{D};
        $v =~ /^\d+$/  or die "-D$v: integer is required.\n";
        $Kook::Config::DEBUG_LEVEL = 0 + $v;
    }
    ## find cookbook
    my $bookname = $opts->{f} || $Kook::Config::COOKBOOK_FILENAME;
    my $bookpath = $bookname;
    if ($opts->{R}) {
        while (! -e $bookpath) {
            my $parent = "../$bookpath";
            last if realpath($parent) eq realpath($bookpath);
            $bookpath = $parent;
        }
    }
    my $s = $opts->{f} ? '-f ' : '';
    -e $bookpath  or die "$s$bookname: not found.\n";
    -f $bookpath  or die "$s$bookname: not a file.\n";
    ## change directory if cookbook is in parent directory
    if ($bookname ne $bookpath) {
        my $path = substr($bookpath, 0, - length($bookname));
        chdir $path;
    }
    ## property file
    my $props = $this->_load_property_file();
    map { $props->{$_} = $longopts->{$_} } keys %$longopts if %$longopts;
    ## create cookbook
    my $cookbook = Kook::Cookbook->new($bookname, $props);
    ## list recipes
    if ($opts->{l} || $opts->{L}) {
        $this->_list_recipes($cookbook, $opts);
        return 0;
    }
    ## get default product if no argument
    if (! @$rests) {
        my $default_product = $cookbook->default_product();
        unless ($default_product) {
            my $command = $this->{command};
            print STDERR "*** $command: target is not given.\n";
            print STDERR "*** '$command -l' or '$command -L' shows recipes and properties.\n";
            print STDERR "*** (or set '\$kook->{default}' in your kookbook.)\n";
            return 1;
        }
        $rests = [$default_product];
    }
    ## start cooking
    my $kitchen = Kook::Kitchen->new($cookbook);
    $kitchen->start_cooking(@$rests);
    ##
    return 0;
}

sub _list_recipes {
    my ($this, $cookbook, $opts)  = @_;
    my $show_all = $opts->{L};
    my $format   = $Kook::Config::RECIPE_LIST_FORMAT;  # "  %-20s: %s\n";
    my $format2  = $Kook::Config::RECIPE_OPTS_FORMAT;  # "    %-20s  %s\n";
    ## find default recipe
    my $default_recipe;
    my $default = $cookbook->default_product();
    if ($default) {
        $default_recipe = $cookbook->find_recipe($default);
        if (! $default_recipe) {
            print STDOUT "*** \$kook->{default} = '$default': recipe not found.\n";
        }
    }
    ## properties
    print "Properties:\n";
    for (@{$cookbook->{property_tuples}}) {
        my ($name, $value, $desc) = @$_;
        next if ! $show_all && $desc == -1;
        printf($format, $name, repr($value));
    }
    print "\n";
    ## task and file recipes
    my @task_recipes = ( @{$cookbook->{specific_task_recipes}}, @{$cookbook->{generic_task_recipes}} );
    my @file_recipes = ( @{$cookbook->{specific_file_recipes}}, @{$cookbook->{generic_file_recipes}} );
    my $kind = $default_recipe ? $default_recipe->{kind} : undef;
    my $s = " (default=$default)";
    my $title;
    $title = "Task recipes" . ($kind eq 'task' ? $s : '') . ':';
    $this->__list_recipes($title, \@task_recipes, $format, $format2, $show_all);
    print "\n";
    $title = "File recipes" . ($kind eq 'file' ? $s : '') . ':';
    $this->__list_recipes($title, \@file_recipes, $format, $format2, $show_all);
    print "\n";
    ## tips
    if (! $opts->{q}) {
        my $tip = $this->get_tip($default);
        print "(Tips: $tip)\n";
    }
    return 0;
}

sub __list_recipes {
    my ($this, $title, $recipes, $format, $format2, $show_all) = @_;
    print $title, "\n";
    for my $recipe (@$recipes) {
        next unless $show_all || $recipe->{desc};
        printf($format, $recipe->{product}, $recipe->{desc});
        next unless $Kook::Config::VERBOSE;
        next unless $recipe->{spices} && @{$recipe->{spices}};
        my $optparser = Kook::Util::CommandOptionParser->new($recipe->{spices});
        for (@{$optparser->{helps}}) {
            my ($opt, $desc) = @$_;
            printf($format2, $opt, $desc) if $desc;
        }
    }
}

our $TIPS = [
    "you can set '\$kook->{default}' in your kookbook.",
    "you can override properties with '--propname=propvalue'.",
    "it is able to separate properties into 'Properties.pl' file.",
    "try 'kk' command which is shortcat for 'plkook' command.",
    "ingreds=>['\$(1).c', if_exists('\$(1).h')] is a friend of C programmer.",
    #"'c%\"gcc $(ingred)\"' is more natural than '\"gcc %s\" % c.ingreds[0]'.",
];

sub get_tip {
    my ($this, $default_product) = @_;
    my $len = @$TIPS;
    my $index = int(rand() * $len);
    if ($default_product) {
        ## don't display tip about default product
        $index ||= int(rand() * $len);
        $index ||= 1;
    }
    else {
        ## show tip about default product frequently
        $index = 0 if rand() < 0.5;
    }
    return $TIPS->[$index];
}

sub main {
    my ($this) = @_;
    my $status;
    eval {
        $status = $this->invoke();
    };
    if ($@) {
        print STDERR $@;
        $status = 1;
    }
    return $status;
}


package Kook::MainApplication;
our @ISA = ('Kook::Main');
use strict;
use Data::Dumper;
use File::Basename;

use Kook::Misc ('_debug', '_trace');
use Kook::Util ('repr', 'first');

my $optdef_strs2 = [
    "-h:      help",
    #"--help: help",
    #"-V:      version",
    "-D[N]:   debug level (default: 1)",
    #"-q:      quiet",
    #"-f file: kookbook",
    "-F:      forcedly",
    #"-l:      list public recipes",
    #"-L:      list all recipes",
    #"-n:      not invoke (dry run)",
    "-X file:",
    "--name=value: property name and value",
    "--name:       property name and value(=1)",
];

sub invoke {
    my ($this) = @_;
    my $quiet = $Kook::Config::VERBOSE;
    $Kook::Config::VERBOSE = 0;
    eval {
        $this->_invoke();
    };
    $Kook::Config::VERBOSE = $quiet;
    die $@ if $@;
}

sub _invoke {
    my ($this) = @_;
    ## parse command-line options
    my $optparser = Kook::Util::CommandOptionParser->new($optdef_strs2);
    my ($opts, $longopts, $rests) = $optparser->parse2($this->{argv}, $this->{command});
    _trace("opts="     . repr($opts));
    _trace("longopts=" . repr($longopts));
    _trace("rests="    . repr($rests));
    ## handle options
    my $bookname = $opts->{X}  or die "-X: script filename required.\n";
    $this->{command} = basename($bookname);
    ## property file
    my $props = $this->_load_property_file();
    if (%$longopts) {
        map { $props->{$_} = $longopts->{$_} } keys %$longopts;
    }
    ## help
    if ($opts->{h} || $longopts->{help} == 1) {
        my $target = $rests->[0];
        $this->_show_help($bookname, $props, $target, $optparser);
        return 0;
    }
    ## other options
    #if ($opts->{V}) {
    #    print $Kook::RELEASE, "\n";
    #    return 0;
    #}
    #if ($opts->{q}) { $Kook::Config::VERBOSE = 0; }
    if ($opts->{F}) { $Kook::Config::FORCED = 1; }
    if ($opts->{D}) {
        $opts->{D} =~ /^\d+$/  or die "-D$opts->{D}: integer is required.\n";
        $Kook::Config::DEBUG_LEVEL = 0 + $opts->{D};
    }
    ## create cookbook
    my $cookbook = Kook::Cookbook->new($bookname, $props);
    if (! @$rests) {
        my $default_product = $cookbook->default_product()  or
            die "sub-command is required (try '-h' to show all sub-commands).\n";
        $rests = [$default_product];
    }
    ## check whether recipe exists or not
    my $target = $rests->[0];
    my $recipes = $cookbook->{specific_task_recipes};
    my $recipe = first { $_->{product} eq $target } @$recipes  or
        die "$target: sub-command not found.\n";
    ## start cooking
    my $kitchen = Kook::Kitchen->new($cookbook);
    $kitchen->start_cooking(@$rests);
    ##
    return 0;
}

sub _show_help {
    my ($this, $bookname, $props, $target, $optparser) = @_;
    my $cookbook = Kook::Cookbook->new($bookname, $props);
    $target ? $this->_show_help_for($cookbook, $target)
            : $this->_show_help_all($cookbook, $optparser);
}

sub _show_help_for {
    my ($this, $cookbook, $target) = @_;
    my $recipes = $cookbook->{specific_task_recipes};
    my $recipe = first { $_->{product} eq $target } @$recipes  or
        die "$target: sub command not found.\n";
    print "$this->{command} $target - $recipe->{desc}\n";
    if ($recipe->{spices} && @{$recipe->{spices}}) {
        my $optparser = Kook::Util::CommandOptionParser->new($recipe->{spices});
        for (@{$optparser->{helps}}) {
            my ($opt, $desc) = @$_;
            printf $Kook::Config::SUBCOMMANDS_FORMAT, $opt, $desc if $desc;
        }
    }
}

sub _show_help_all {
    my ($this, $cookbook, $optparser) = @_;
    my $recipes = $cookbook->{specific_task_recipes};
    my $desc = $cookbook->{desc};
    print "$this->{command} - $desc\n";
    if (0) {
        print "\n";
        print "global-options:\n";
        print $optparser->help();
    }
    print "\n";
    print "sub-commands:\n";
    for my $recipe (@$recipes) {
        printf $Kook::Config::OPTION_HELP_FORMAT, $recipe->{product}, $recipe->{desc} if $recipe->{desc};
    }
    print "\n";
    print "(Type '$this->{command} -h subcommand' to show options of sub-commands.)\n";
}

sub main {
    my ($this) = @_;
    return $this->invoke();
}


1;
