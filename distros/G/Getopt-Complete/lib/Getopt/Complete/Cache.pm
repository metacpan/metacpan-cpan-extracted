package Getopt::Complete::Cache;

our $VERSION = $Getopt::Complete::VERSION;

use strict;
use warnings;

our $cache_path;
our $cache_is_stale;

sub import {
    my $self = shift;
    my %args = @_;

    my $class = delete $args{class};
    my $file  = delete $args{file}  if exists $args{file};
    my $above = 0; $above = delete $args{above} if exists $args{above};
    my $dynamic_caching = 0; $dynamic_caching = delete $args{dynamic_caching} if exists $args{dynamic_caching};
    my $comp_cword = $ENV{COMP_CWORD}; $comp_cword = delete $args{comp_cword} if exists $args{comp_cword};

    if (%args) {
        require Data::Dumper;
        die "Unknown params passed to " . __PACKAGE__ .
            Data::Dumper::Dumper(\@_);
    }

    if ($class and $file) {
        die __PACKAGE__ . " received both a class and file param: $class, $file!";
    }

    return unless ($comp_cword);

    # doesn't detect
    my $module_path;

    if ($class) {
        ($module_path, $cache_path) = $self->module_and_cache_paths_for_package($class, $above);
        $cache_path ||= $module_path . '.opts';
    }
    else {
        use FindBin;
        $module_path = $FindBin::RealBin . '/' . $FindBin::RealScript;
        $cache_path = $file || $module_path . '.opts';
    }
    
    # TODO: This does not quite work yet.
    if ($dynamic_caching && -e $cache_path) {
        my $my_mtime = (stat($module_path))[9];

        # if the module has a directory with changes newer than the module,
        # use its mtime as the change time
        my $module_dir = $module_path;
        $module_dir =~ s/.pm$//;
        if (-e $module_dir) {
            if ((stat($module_dir))[9] > $my_mtime) {
                $my_mtime = (stat($module_dir))[9];
            }
        }
        
        my $cache_mtime = (stat($cache_path))[9];
        unless ($cache_mtime >= $my_mtime) {
            print STDERR "\nstale completion cache: refreshing $cache_path...\n";
            unlink $cache_path;
        }
    }
    
    $cache_path = $file if ($file);
    
    if ( -f $cache_path && -s $cache_path) {
        my $fh;
        open($fh, $cache_path);
        if ($fh) {
            my $src = join('', <$fh>);
            require Getopt::Complete;
            my $spec = eval $src;
            if (@$spec) {
                Getopt::Complete->import(@$spec);
            }
        }
        return 1;
    }
    else {
        die "Unable to open file: $cache_path\n";
    }
}

sub module_and_cache_paths_for_package {
    my $self = shift;
    my $class = shift;
    my $above = shift;
    my $path = $class;
    $path =~ s/::/\//g;
    $path = '/' . $path . '.pm';
    
    my ($mod_path, $opt_path);
    
    # if above, check cwd upwards for class location
    if ($above) {
        require Cwd;
        $mod_path = Cwd::cwd();
        $mod_path =~ s/([^\/])$/$1\//;
        until (-e "$mod_path$path" || $mod_path eq '/') {
            $mod_path =~ s/[^\/]+\/$//; # remove last folder and try again
        }
        $mod_path .= $path;
        $opt_path = $mod_path . '.opts';
    }
    
    # otherwise search perl's path
    unless ($mod_path && -e "$mod_path") {
        my (@mod_paths) = map { ($_ . $path) } @INC;
        ($mod_path) = grep { -e $_ } @mod_paths;    
    }
    unless ($opt_path && -e "$opt_path") {
        my (@opt_paths) = map { ($_ . $path . '.opts' ) } @INC;
        ($opt_path) = grep { -e $_ } @opt_paths;
    }

    return ($mod_path, $opt_path);
}

sub generate {
    print STDERR "ending\n";
    eval {
        print STDERR "evaling $cache_path\n";
        unless (-e $cache_path) {
            print STDERR "found $cache_path\n";
            no warnings;
            my $a = $Getopt::Complete::ARGS;
            print STDERR "args are $a\n";
            use warnings;
            if ($a) {
                print STDERR ">> got args $a\n";
                if (my $o = $a->options) {
                    print STDERR ">> got opts $o\n";
                    my $c = $o->{completion_handlers};
                    my @modules;
                    if ($c) {
                        print STDERR ">> got completions $c\n";
                        my $has_callbacks = 0;
                        for my $key (keys %$c) {
                            my $completions = $c->{$key};
                            if (ref($completions) eq 'SCALAR') {
                                push @modules, $$completions;
                            }
                            elsif(ref($completions) eq 'CODE') {
                                warn "cannot use cached completions with anonymous callbacks!";
                                $has_callbacks = 1;
                            }
                        }
                        unless ($has_callbacks) {
                            my $fh;
                            open($fh,$cache_path);
                            if ($fh) {
                                warn "caching options for $cache_path...\n";
                                my $src = Data::Dumper::Dumper($c);
                                #$src =~ s/^\$VAR1/\$${class}::OPTS_SPEC/;
                                #print STDERR ">> $src\n";
                                $fh->print($src);
                                #require Data::Dumper;
                                #my $src = Data::Dumper::Dumper($c);
                            }
                        }
                        for my $module (@modules) {
                            print STDERR "trying mod $module\n";
                            local $ENV{GETOPT_COMPLETE_CACHE} = 1;
                            eval "use $module";
                            die $@ if $@;
                            no strict;
                            no warnings;
                            $spec = ${ $class . '::OPTS_SPEC' };
                            my ($other_module_path,$other_cache_path) = $self->module_and_cache_paths_for_package($module);
                            $other_cache_path ||= $other_module_path . '.opts';
                            my $fh;
                            open($fh,$other_cache_path);
                            if ($fh) {
                                warn "caching options for $module at $other_cache_path...\n";
                                my $src = Data::Dumper::Dumper($c);
                                $src =~ s/^\$VAR1/\$${class}::OPTS_SPEC/;
                                #print STDERR ">> $src\n";
                                $fh->print($src);
                                #require Data::Dumper;
                                #my $src = Data::Dumper::Dumper($c);
                            }
                        }
                    }
                }
            }
        }
    };
    print STDERR ">>>> $@\n" if $@;
}

1;

=pod 

=head1 NAME

Getopt::Complete::Cache - cache options next-to the command they apply-to

=head1 VERSION

This document describes Getopt::Complete::Cache 0.26.

=head1 SYNOPSIS

Presuming MyApp.pm isa Command, and "myapp" is an executable like:

    use MyApp;
    MyApp->execute_with_shell_params_and_exit();

Add this BEFORE using the MyApp module:

    use Getopt::Complete::Cache class => 'MyApp';
    use MyApp;
    MyApp->execute_with_shell_params_and_exit();

Now the shell will look for MyApp.pm.opts during completion
and will never actually load the MyApp.pm module during tab-completion.

The .opts file is autogenerated upon the first attempt to find it.

=head1 DESCRIPTION

This module is for the obscure case in which:
1. the compile time on an executable is sluggish, and we don't want to have sluggish tab-completion
2. the command-line should be cached relative to a given module name

This is most useful with classes implementing the Command.pm API.  Since these modules may form a
large command tree, the caching occurs at individual levels in the tree separately.

=cut


