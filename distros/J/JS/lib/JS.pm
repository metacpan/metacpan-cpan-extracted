use strict; use warnings;
package JS;
our $VERSION = '0.29';

use File::Find;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}

sub run {
    my $self = shift;
    my @args = @_;

    if (! @args) {
        return $self->list_all();
    }
    for my $js_module (@args) {
        $js_module =~ s/\.js$//;
        my @path = $self->find_js_path($js_module)
          or warn("*** Can't find $js_module\n"), next;
        print join "\n", sort(@path), "";
    }
}

sub list_all {
    my $found = {};
    find {
        wanted => sub {
            return unless -f $_;
            return if /\.(?:pm|pod|packlist)$/;
            return if /^\./;
            my $dir = $File::Find::dir;
            $dir =~ s{.*/JS\b(/|$)(.*)}{$2} or return;
            my $module = $dir ? "$dir/$_" : $_;
            if ($module =~ s/\.js$//) {
                $module =~ s/[\/\\]+/./g;
            }
            return if $found->{$module}++;
            print $module, "\n";
        },
    }, grep {-d $_ and $_ ne '.'} @INC;
}

sub find_js_path {
    my $self = shift;
    my $module = shift;
    unless ($module =~ /\//) {
        $module =~ s/(?:\.)/\//g;
    }
    $module =~ s/(?:::)/\//g;
    $module =~ s/\*$/.*/;

    my $found = {};
    my @module_path;
    find {
        wanted => sub {
            my $path = $File::Find::name;
            while (1) {
                return if -d $_;
                return if $path =~ /[\\\/]$module\.pm$/i;
                return if $path =~ /[\\\/]$module\.pod$/i;
                last if $path =~ /[\\\/]$module$/i;
                last if $path =~ /[\\\/]$module\.js(?:\.gz)?$/i;
                return;
            }
            return if $found->{$path}++;
            push @module_path, $path;
        },
    }, grep {-d $_ and $_ ne '.'} @INC;
    return @module_path;
}

1;
