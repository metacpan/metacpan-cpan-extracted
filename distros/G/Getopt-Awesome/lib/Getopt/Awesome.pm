#
# Getopt::Awesome
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 09/25/2009 11:43:15 AM
package Getopt::Awesome;

=head1 NAME

Getopt::Awesome - Let your modules define/export their own arguments

=head1 DESCRIPTION

First of, this module was very inspired in the Getopt::Modular CPAN package
however at the moment of using it I found it was giving me "more" of what I
was looking so I thought I could borrow some ideas of it, make it lighter
and add some of the features/functionalities I was looking for and so this
is the result: a module I've been using every day for all my perl scripts
and modules, though would be nice to give it to the Perl community.

Now, this module is handy if you want to give your modules the freedom of
definining their own "getopt options" so next time they get called (or *used*)
the options will be available in the form of arguments (--foo, --bar).

Another feature of this module is that when user asks for help (-h or --help)
a usage will be printed by showing all the options available by the current
perl script and by all the modules in use.

All options are prefixed by the package name in lowercase where namespace
separator (::) gets replaced by a dash (-), so --help will return:

    --foo-bar-option   Description.
    --foo-bar-option2  Description 2.

and so on..

See the SYNOPSYS section for examples.

B<Notes:>

=over 4

=item *

The use of short aliases is not supported for options defined in modules, this
feature (provided by Getopt) is only available in the main script (.pl)

=item *

In your perl script (.pl) remember to call parse_opts otherwise the values of
the options you request might be undef, empty or have their default values.

=item *

I<Remember:> ARGV is ONLY parsed when parse_opt is called.

=back

=head1 SYNOPSYS

    package Your::Package;

    use Getopt::Awesome qw(:common);
    define_option('foo=s', 'Foo bar');
    # ...or...

    define_options(
        ('foo=s', 'Foo'),
        ('bar=s', 'Bar'));

    parse_opts();
    my $foo_val = get_opt('option_name', 'Default value');

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2009 by Pablo Fischer
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
    
=cut
use 5.006;

use strict;
use warnings;
use vars qw($no_usage $app_name $no_usage_exit);
use Getopt::Long qw(
    :config
    require_order
    gnu_compat
    no_ignore_case);
use Text::Wrap;
use Exporter 'import';

our @EXPORT_OK = qw(
    usage
    define_option
    define_options
    get_opt
    set_opt
    parse_opts
    %args);
our @EXPORT = qw(parse_opts);
our %EXPORT_TAGS = (
    'all' => [ @EXPORT_OK ],
    'common' => [ qw(define_option define_options get_opt set_opt) ],
);

our $VERSION = '0.1.3';


my (%options, $parsed_args, $show_usage, %args);

=head1 FUNCTIONS

=over 4

=item B<define_options (@options)>

    use Getopt::Awesome;
    Getopt::Awesome qw(:common);

    define_options(
        ('option_name', 'Option description')
    );

It defines the given options for the package/script that is making *the call*.

Please note the options defined in the current caller package are not shared
with other modules unless it's explicitly specified (see I<get_opt()>).

Each array item should consist at least of 1 item with a max of 2. The first
parameter should be the option name while the second one (optional) is the
description.

Some notes about the option name, the first item of every array:

=over 4

=item *

It's a required parameter.

=item *

It accepts any of the C<Getopt::Long> option name styles (=s, !, =s@, etc).

=back

=cut
sub define_options {
    my $new_options = shift;
    if (ref $new_options ne 'ARRAY') {
        die 'The options should be passed as an array';
    }
    my $current_package = _get_option_package();
    foreach my $opt (@$new_options) {
        my ($option_name, $option_description) = (@$opt);
        if (!$option_name) {
            die "Option name wasn't found";
        }
        if ($option_name =~ /\|/ && $current_package ne 'main') {
            die "Sorry but no aliases ($option_name) are suported for " .
                "modules except main";
        }
        $options{$current_package}{$option_name} = $option_description;
    }
}

=item B<define_option( $name, $description )>

    use Getopt::Awesome qw(:common);

    define_option('option_name', 'Description');

It calls the I<define_options> subroutine for adding the given option
(I<$name>) with an optional description (I<$description>).

Please refer to the documentation of C<define_options> for a more complete
description about it, but basically some notes:

=over 4

=item *

The option name is a required parameter

=item *

The option accepts any of te C<Getopt::Long> option name styles.

=back

=cut
sub define_option {
    # Find the right option, we don't like namespaces or classes..
    my ($option_name, $option_description) = @_;
    define_options([[$option_name, $option_description]]);
}

=item B<get_opt($option_name, $default_value)>

    use Getopt::Awesome qw(:common);

    my $val = get_opt('option_name', 'Some default opt');
    # Gets the 'foome' option value of Foo::Bar module and defaults to 'foobie'
    my $val = get_opt('Foo::Bar::foome', 'foobie');

It will return the value of the given option, if there's no option set then
undefined will be returned.

Please note that if the option is set to expect a list you will receive a list,
same for integer, strings, booleans, etc. Same as it happens with the
Getopt::Long.

=cut
sub get_opt {
    my ($option_name, $default_value) = @_;
    return $default_value unless $option_name;
    # The option name comes with a namespace?
    my $package = _get_option_package();
    if ($option_name =~ /(\S+::){1,}(\S+)$/) {
        $package = substr($1, 0, -2);
        $option_name = $2;
    }
    if ($package ne 'main') {
        $package = lc $package;
        $package =~ s/::/-/g;
        $option_name = $package . '-' . $option_name;
    }
    if (defined $args{$option_name}) {
        return $args{$option_name};
    } else {
        if (defined $default_value) {
            return $default_value;
        }
    }
    return '';
}

=item B<set_opt ($option_name, $value)>

    use Getopt::Awesome qw(:common);

    set_opt('option_name', 'Value');
    # Sets the 'foome' option value to foobie of the Foo::Bar package.
    set_opt('Foo::Bar::foome', 'foobie')

Sets the given value to the given option.

=cut
sub set_opt {
    my ($option_name, $option_value) = @_;
    my $package = _get_option_package();
    if ($option_name =~ /(\S+::){1,}(\S+)$/) {
        $package = substr($1, 0, -2);
        $option_name = $2;
    }
    if ($package ne 'main') {
        $package = lc $package;
        $package =~ s/::/-/g;
        $option_name = $package . '-' . $option_name;
    }
    $args{$option_name} = $option_value;
}

=item B<parse_opts()>

This subroutine should never be called directly unless you want to re-parse the
arguments or that your module is not getting called from a perl script (.pl).

In case you want to call it:

    use Getopt::Awesome qw(:common);

    parse_opts();

=cut
sub parse_opts {
    my %all_options = _build_all_options();
    if (!defined $no_usage) {
        $all_options{'h|help'} = 1;
    }
    my $res = GetOptions(
        \%args,
        keys %all_options);
    if ($args{'h'} ||
        (!defined $no_usage && !%args)) {
        usage();
        if (!defined $no_usage_exit) {
            exit(1);
        }
    }
}

=item B<usage()>

Based on all the current options it returns a nice and helpful 'guide'
of all the available options.

Although the usage gets called directly if a -h or --help is passed
and also if no_usage is set you can call it directly:

    use Getopt::Awesome qw(:all);

    usage();

=back

=cut
sub usage {
    my (%main_options, %other_options);
    if ($app_name) {
        print "$app_name\n";
    }
    if (scalar %options ge 1) {
        print "Options:\n";
    }
    $Text::Wrap::columns = 80;
    my @packages = keys %options;
    my ($main_pos) = grep($packages[$_] eq 'main', 0 .. $#packages);
    # Lets make sure that main options are showed first
    if ($main_pos) {
        splice(@packages, $main_pos, 1);
        unshift(@packages, 'main');
    }
    foreach my $package (@packages) {
        my $package_option_prefix = lc $package;
        $package_option_prefix =~ s/::/-/g;
        if ($package ne 'main') {
            print "\nOptions from: $package\n";
            print "Prepend --$package_option_prefix to use them\n";
        }
        foreach my $opt (keys %{$options{$package}}) {
            my ($option_name, $option_type) = split('=', $opt);
            # Perhaps option is a + or a !?
            if (substr($option_name, -1, 1) eq '!') {
                $option_type = '!';
                $option_name =~ s/!//;
            } elsif(substr($option_name, -1, 1) eq '+') {
                $option_type = '+';
                $option_name =~ s/\+//;
            }
            if (!defined $option_type) {
                $option_type = '';
            }
            $option_name=~ s/[\!,\+]//g;
            my @aliases = split('\|', $option_name);
            foreach (@aliases) {
                my $dash = length $_ eq 1 ? '-' : '--';
                if ($package eq 'main') {
                    $_ = "$dash$_";
                } else {
                    $_ = "-$_";
                }
            }
            my $description = $options{$package}{$opt};
            printf "  %-35s", join(', ', @aliases);
            printf "%-10s", $description;
            print "\n";
        }
    }
}


################### PRIVATE METHODS ####################
#
# Should _never_ be called directly. It will parse all the options we have and
# will prepare a hash that C<Getopt::Long::Getoptions> will use to parse the
# arguments provided by @ARGV.
sub _build_all_options {
    my %get_options;
    foreach my $package (keys %options) {
        foreach my $opt (keys %{$options{$package}}) {
            my $option_name = $opt;
            if ($package ne 'main') {
                $option_name = lc $package;
                $option_name =~ s/::/-/g;
                $option_name = $option_name . '-' . $opt;
            }
            $get_options{$option_name} = 1;
        }
    }
    return %get_options;
}

#
# Returns the right option package where the options are going to be stored.
#
sub _get_option_package {
    # Look for the real package, it shouldn't be this package
    my ($caller_package, $tries, $max_tries) = ('', 0, 10);
    while($tries ne $max_tries) {
        ($caller_package) = caller($tries);
        if ($caller_package eq __PACKAGE__) {
            $tries += 1;
        } else {
            last;
        }
    }
    if ($caller_package eq __PACKAGE__) {
        return 'main';
    }
    if (!$caller_package) {
        return 'main';
    }
    return $caller_package;
}

1;
