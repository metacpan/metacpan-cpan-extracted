package Devel::Trace::Subs;
use 5.008;
use strict;
use warnings;

use Data::Dumper;
use Devel::Trace::Subs::HTML qw(html);
use Devel::Trace::Subs::Text qw(text);
use Exporter;
use Storable;
use Symbol qw(delete_package);

our $VERSION = '0.24';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    trace
    trace_dump
    install_trace
    remove_trace
);

$SIG{INT} = sub { 'this ensures END runs if ^C is pressed'; };

sub trace {

    return unless $ENV{DTS_ENABLE};

    my $flush_flow = $ENV{DTS_FLUSH_FLOW};

    _env();

    my $data = _store();

    my $flow_count = ++$ENV{DTS_FLOW_COUNT};

    my $flow = {
        name => $flow_count,
        value => (caller(1))[3] || 'main()'
    };

    push @{$data->{flow}}, $flow;

    push @{$data->{stack}}, {
        in       => (caller(1))[3] || '-',
        package  => (caller(1))[0] || '-',
        sub      => (caller(2))[3] || '-',
        filename => (caller(1))[1] || '-',
        line     => (caller(1))[2] || '-',
    };

    _store($data);

    if ($flush_flow){
        print "\n** $flow->{name} :: $flow->{value} **\n";
    }

    if (defined wantarray){
        return $data;
    }
}
sub trace_dump {

    if (! $ENV{DTS_PID}){
        die "\nCan't call trace_dump() without calling trace()\n\n" .
            'Make sure to set $ENV{DTS_ENABLE} = 1;' . "\n\n";
    }

    my %p = @_;

    my $want = $p{want};
    my $out_type = $p{type};
    my $file = $p{file};

    my $data = _store();

    if ($want && $want eq 'stack'){
        if ($out_type && $out_type eq 'html') {
            html(
                file => $file,
                want => $want,
                data => $data->{stack}
            );
        }
        else {
            text(
                want => 'stack',
                data => $data->{stack},
                file => $file
            );
        }
    }
    if ($want && $want eq 'flow'){
        if ($out_type && $out_type eq 'html') {
            html(
                file => $file,
                want => $want,
                data => $data->{flow}
            );
        }
        else {
            text(
                want => 'flow',
                data => $data->{flow},
                file => $file
            );
        }
    }
    if (! $want){
        if ($out_type && $out_type eq 'html') {
            html(
                file => $file,
                data => $data
            );
        }
        else {
            text(
                data => {
                    flow => $data->{flow},
                    stack => $data->{stack}
                },
                file => $file
            );
        }
    }
}
sub install_trace {

    eval {
        require Devel::Examine::Subs;
        Devel::Examine::Subs->import();
    };

    $@ = 1 if $ENV{EVAL_TEST}; # for test coverage

    if ($@){
        die "Devel::Examine::Subs isn't installed. Can't run install_trace(): $@";
    }

    my %p = @_;

    my $file        = $p{file};
    my $extensions  = $p{extensions};
    my $inject      = $p{inject};

    my $des_use = Devel::Examine::Subs->new(file => $file,);

    remove_trace(file => $file);

    # this is a DES pre_proc

    $des_use->inject(inject_use => _inject_use());

    my $des = Devel::Examine::Subs->new(
        file        => $file,
        extensions  => $extensions,
    );

    $inject = $p{inject} || _inject_code();

    $des->inject(
        inject_after_sub_def => $inject,
    );
    
}
sub remove_trace {
 
    eval {
        require Devel::Examine::Subs;
        Devel::Examine::Subs->import();
    };

    $@ = 1 if $ENV{EVAL_TEST}; # for test coverage

    if ($@){
        die "Devel::Examine::Subs isn't installed. Can't run remove_trace(): $@";
    }
   
    my %p       = @_;
    my $file    = $p{file};

    my $des = Devel::Examine::Subs->new( file => $file ); 

    $des->remove(delete => [qr/injected by Devel::Trace::Subs/]);
}
sub _inject_code {
    return [
        'trace() if $ENV{DTS_ENABLE}; # injected by Devel::Trace::Subs',
    ];
}
sub _inject_use {
    return [
        'use Devel::Trace::Subs qw(trace trace_dump); ' .
        '# injected by Devel::Trace::Subs',
    ];
}
sub _env {

    my $pid = $$;
    $ENV{DTS_PID} = $pid;

    return $pid;
}
sub _store {

    my ($data) = @_;

    my $store = "DTS_" . join('_', ($$ x 3)) . ".dat";

    $ENV{DTS_STORE} = $store;

    my $struct;

    if (-f $store){
        $struct = retrieve($store);
    }
    else {
        $struct = {};
    }

    return $struct if ! $data;

    store($data, $store);

}
sub _fold_placeholder {};

END {
    unlink $ENV{DTS_STORE} if $ENV{DTS_STORE};
}

__END__

=head1 NAME

Devel::Trace::Subs - Generate, track, store and print code flow and stack traces

=for html
<a href="https://github.com/stevieb9/devel-trace-subs/actions"><img src="https://github.com/stevieb9/devel-trace-subs/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/devel-trace-subs?branch=master'><img src='https://coveralls.io/repos/stevieb9/devel-trace-subs/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Devel::Trace::Subs qw(trace trace_dump install_trace remove_trace);

Add a trace() call to the top of all your subs

    trace(); # or even better: $trace() if $ENV{DTS_ENABLE};

Enable the module anywhere in the stack (preferably the calling script)

    $ENV{DTS_ENABLE} = 1;

From anywhere (typically near the end of the calling script) dump the output

    trace_dump();

Automate the installation into a file (or all files in a directory). Requires
L<Devel::Examine::Subs> to be installed.

    install_trace(file => 'filename'); # or directory, or 'Module::Name'

Remove the effects of install_trace(). Requires L<Devel::Examine::Subs> to be
installed.

    remove_trace(file => 'filename')

See L<EXAMPLES|Devel::Trace::Subs/EXAMPLES> for further details.

=head1 DESCRIPTION

This module facilitates keeping track of a project's code flow and stack
trace information in calls between subroutines.

Optionally, you can use this module to automatically inject the appropriate
C<trace()> calls into all subs in individual files, all Perl files within a 
directory structure, or even in production files by specifying its 
C<Module::Name>.

It also has the facility to undo what was done by the automatic installation
mentioned above.

=head1 EXPORT

None by default. See L<EXPORT_OK|Devel::Trace::Subs/EXPORT_OK>.

=head1 EXPORT_OK

C<trace, trace_dump, install_trace, remove_trace>

=head1 FUNCTIONS

=head2 C<trace>

Takes no parameters.

In order to enable tracing, you must set C<$ENV{DTS_ENABLE}> to a true value
somewhere in the call stack (preferably in the calling script). Simply set to
a false value (or remove it) to disable this module.

Puts the call onto the stack trace. Call it in scalar context to retrieve the
data structure as it currently sits.

Note: It is best to write the call to this function within an C<if> statement, eg:
C<trace() if $ENV{DTS_ENABLE};>. That way, if you decide to disable tracing,
you'll short circuit the process of having the module's C<trace()> function
being loaded and doing this for you.

If you set C<$ENV{DTS_FLUSH_FLOW}> to a true value, we'll print to STDOUT a single 
line of code flow during each C<trace()> call. This helps in figuring out where a
program is having trouble, but the program itself isn't outputting anything useful.

=head2 C<trace_dump(%params)>

Parameters:

    want => 'flow'|'stack'

Optional, String: Display either the code flow or stack trace.

Default: None (display both flow and trace information).

    type => 'html'

Optional, String: The display output format. Only valid value is C<html>.

Default: None (Display output in plain text).

    file => 'filename.ext'

Optional, String: If sent in, we'll write the output to the file specified
instead of C<STDOUT>. We'll C<die()> if the file can't be opened for writing.

Default: None (Write output to C<STDOUT>).

=head2 C<install_trace>

Automatically injects the necessary code into Perl files to facilitate stack
tracing. Requires L<Devel::Examine::Subs> to be installed.

Parameters:

    file => 'filename.ext'

Mandatory, String: 'filename' can be the name of a single file, a directory, or even a
'Module::Name'. If the filename is a directory, we'll iterate recursively
through the directory, and make the changes to all C<.pl> and C<.pm> files
underneath of it (by default). If filename is a 'Module::Name', we'll load the
file for that module dynamically, and modify it.

CAUTION: this will edit live production files.

    extensions => ['*.pl', '*.pm']

Optional, Array reference: By default, we change all C<*.pm> and C<*.pl> files.
Specify only the extensions you want by adding them into this array reference.
Anything that C<File::Find::Rule::name()> accepts can be passed in here.

    inject => ['your code here;', 'more code;']

Optional, Array refernce of strings: The lines of code supplied here will
override the default. Note that C<remove_trace()> will not remove these lines,
and for uninstall, you'll have to manually delete them.

=head2 C<remove_trace>

Automatically remove all remnants of this module from a file or files, that were
added by this module's C<install_trace()> function. Requires L<Devel::Examine::Subs>
to be installed.

Parameters:

    file => 'filename.ext'

Optional, String: 'filename' can be the name of a file, a directory or a
'Module::Name'.

=cut

=head1 EXAMPLES

One-liner to install into a live module:

    sudo perl -MDevel::Trace::Subs=install_trace -e 'install_trace(file => "Data::Dump");'

One-liner to test that it worked:

    perl -MData::Dump -MDevel::Trace::Subs=trace_dump -e '$ENV{DTS_TRACE}=1; dd {a=>1}; trace_dump();'

One-liner to uninstall:

    sudo perl -MDevel::Trace::Subs=remove_trace -e 'remove_trace(file => "Data::Dump");'

Install into all C<*.pm> files in a directory structure:

    use warnings;
    use strict;

    use Devel::Trace::Subs qw(install_trace);

    install_trace(
                file => '/path/to/files/',
                extensions => ['*.pm'],
             );


=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-trace-flow at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Trace-Subs>.  I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 REPOSITORY

L<https://github.com/stevieb9/devel-trace-subs>

=head1 BUILD REPORTS

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Devel-Trace-Subs>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Trace::Subs


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Trace-Subs>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-Trace-Subs/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Devel::Trace::Subs

