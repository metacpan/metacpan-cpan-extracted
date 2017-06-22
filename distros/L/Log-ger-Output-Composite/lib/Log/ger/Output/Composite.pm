package Log::ger::Output::Composite;

our $DATE = '2017-06-21'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Log::ger::Util;

sub import {
    my ($package, %import_args) = @_;

    # form a linear list of output specifications, and require the output
    # modules
    my @ospecs;
    {
        my $outputs = $import_args{outputs};
        for my $oname (sort keys %$outputs) {
            my $ospec0 = $outputs->{$oname};
            my @ospecs0;
            if (ref $ospec0 eq 'ARRAY') {
                @ospecs0 = map { +{ %{$_} } } @$ospec0;
            } else {
                @ospecs0 = (+{ %{ $ospec0 } });
            }

            die "Invalid output name '$oname'"
                unless $oname =~ /\A\w+(::\w+)*\z/;
            my $mod = "Log::ger::Output::$oname";
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            for my $ospec (@ospecs0) {
                $ospec->{_name} = $oname;
                $ospec->{_mod} = $mod;
                push @ospecs, $ospec;
            }
        }
    }

    my $plugin = sub {
        no strict 'refs';

        my %args = @_;
        my $saved;
        my $codes = [];
        # extract the code from each output module's hook, collect them and call
        # them all in our code
        for my $ospec (@ospecs) {
            my $saved0 = Log::ger::Util::empty_plugins('create_log_routine');
            $saved ||= $saved0;
            my $oargs = $ospec->{args} || {};
            my $mod = $ospec->{_mod};
            $mod->import(%$oargs);
            my $res = Log::ger::run_plugins(
                'create_log_routine', \%args, 1);
            my $code = $res or die "Hook from output module '$mod' ".
                "didn't produce log routine";
            push @$codes, $code;
        }
        Log::ger::Util::restore_plugins('create_log_routine', $saved) if $saved;
        unless (@$codes) {
            $Log::err::_log_is_null = 1;
            return [sub {0}];
        }

        # put the codes in a package so it's addressable from string-eval'ed
        # code
        my ($codes_addr) = "$codes" =~ /0x(\w+)/;
        my $codes_varname = "Log::ger::Stash::A$codes_addr";
        ${$codes_varname} = $codes;

        # generate logger routine
        my $code;
        {
            my @src;
            push @src, "sub {\n";

            #push @src, "  my $ctx = $_[0];\n";

            # XXX filter by category_level

            for my $i (0..$#ospecs) {
                my $ospec = $ospecs[$i];
                push @src, "  # output #$i: $ospec->{_name}\n";
                push @src, "  {\n";
                # XXX filter by output's category_level

                # filter by output level
                if (defined $ospec->{level}) {
                    push @src, "    last unless ".
                        Log::ger::Util::numeric_level($ospec->{level}).
                          " >= $args{level};\n";
                } else {
                    # filter by general level
                    push @src, "  last if \$Log::ger::Current_Level < $args{level};\n";
                }

                # run output's log routine
                push @src, "    \$$codes_varname\->[$i]->(\@_);\n";
                push @src, "  } # output #$i\n\n";
            }

            push @src, "};\n";
            my $src = join("", @src);
            print "D: src for log_$args{str_level}: <<$src>>\n";

            $code = eval $src;
        }

        [$code];
    };

    # install at very high priority (5) to override the default Log::err
    # behavior (at priority 10) that installs null routines to high levels. so
    # we handle all levels.
    Log::ger::Util::add_plugin(
        'create_log_routine', [5, $plugin, __PACKAGE__], 'replace');
}

1;
# ABSTRACT: Composite output

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::ger::Output::Composite - Composite output

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use Log::ger::Output Composite => (
     outputs => {
         # single screen output
         Screen => {
             level => 'info', # set mper-output level. optional.
             args => { use_color=>1 },
         },
         # multiple file outputs
         File   => [
             {
                 level => 'warn',
                 # set per-category, per-output level. optional.
                 category_level => {
                     # don't log myapp.security messages to this file
                     'myapp.security' => 'off',
                 },
                 args => { path=>'/var/log/myapp.log' },
             },
             {
                 path => '/var/log/myapp-security.log',
                 level => 'off',
                 category_level => {
                     # only myapp.security messages go to this file
                     'myapp.security' => 'warn',
                 },
             },
         ],
     },
     # set per-category level. optional.
     category_level => {
        'category1.sub1' => 'info',
        'category2' => 'debug',
        ...
     },
 );
 use Log::ger;

 log_warn "blah...";

=head1 DESCRIPTION

B<EARLY RELEASE>.

This is a L<Log::ger> output that can multiplex output to multiple outputs and
do filtering using per-category level, per-output level, or per-output
per-category level.

=head1 CONFIGURATION

=head2 outputs => hash

=head2 category_level => hash

=head2

=head1 TODO

Per-category level has not been implemented.

Per-output per-category level has not been implemented.

=head1 ENVIRONMENT

=head1 SEE ALSO

Modelled after L<Log::Any::App>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
