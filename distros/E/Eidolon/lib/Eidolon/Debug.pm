package Eidolon::Debug;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Debug.pm - debugging facility
#
# ==============================================================================

use warnings;
use strict;

our $VERSION         = "0.02"; # 2009-05-12 05:50:18
my  $console_started = 0;

# ------------------------------------------------------------------------------
# BEGIN()
# package initialization
# ------------------------------------------------------------------------------
BEGIN 
{
    $SIG{"__WARN__"} = \&warn;
    $SIG{"__DIE__"}  = \&die;
}

# ------------------------------------------------------------------------------
# start_console()
# start debug console
# ------------------------------------------------------------------------------
sub start_console
{
    my $script;

    # print HTTP header
    print "Content-Type: text/html; charset=UTF-8\n\n";

    {
        local $/;
        $script = <DATA>;
    }

    print $script;
    $console_started = 1;
}

# ------------------------------------------------------------------------------
# \@ get_stack()
# get call stack
# ------------------------------------------------------------------------------
sub get_stack
{
    my (@stack, $package, $file, $line, $sub, $level);

    # we don't need this function in stack
    $level = 1;

    # walk stack
    while (($package, $file, $line, $sub) = caller($level)) 
    {
        push @stack, 
        {
            "package" => $package,
            "file"    => $file,
            "line"    => $line,
            "sub"     => $sub
        };

        $level++;
    }

    return \@stack;
}

# ------------------------------------------------------------------------------
# print_stack(@$stack)
# print call stack
# ------------------------------------------------------------------------------
sub print_stack
{
    my ($stack, $level, $sublen, $sub);

    $stack = shift;
    $sublen = 0;
  
    # count fields width
    $sublen = length($_->{"sub"}) > $sublen ? length($_->{"sub"}) : $sublen foreach (@$stack);

    # print stack
    foreach (reverse @$stack) 
    {
        printf
        (
            "{ line: '%05d', sub: '%-${sublen}s', file: '%s' },",
            $_->{"line"},
            $sub ? $sub : "main",
            $_->{"file"}
        );

        $sub = $_->{"sub"};
    }
}

# ------------------------------------------------------------------------------
# warn($message)
# warning handler
# ------------------------------------------------------------------------------
sub warn
{
    my ($message, $stack, $phase);

    $message = shift;
    $phase = defined $^S ? "Runtime" : "Compile";

    start_console unless $console_started;

    $message =~ s/[\r\n]//g;
    $message =~ s/'/\\'/g;

    printf "<script>eidolonDebug.addWarning('$phase warning', '$message');</script>";
}

# ------------------------------------------------------------------------------
# die($message)
# die handler
# ------------------------------------------------------------------------------
sub die
{
    my ($message, $stack, $phase);

    $message = shift;
    $phase = defined $^S ? "Runtime" : "Compile";

    # call original die if called from eval block
    CORE::die($message) if (defined $^S && $^S == 1);

    start_console unless $console_started;

    $message =~ s/[\r\n]//g;
    $message =~ s/'/\\'/g;

    print "<script>eidolonDebug.addError('$phase error', '$message', [";

    # don't print stack on compile errors
    if (defined $^S) 
    {
        print_stack(get_stack);
    }

    print "]);</script>";

    exit;
}

1;

=pod

=head1 NAME

Eidolon::Debug - Eidolon debugging facility.

=head1 SYNOPSIS

In CGI/FCGI gateway of your application (C<index.cgi>/C<index.fcgi>) write:

    use Eidolon::Debug;

=head1 DESCRIPTION

The I<Eidolon::Debug> package provides an easy way to avoid a confusing 
I<Internal Server Error> web server message. It sends HTTP header before 
displaying an error, so you don't need to dig web-server's log to find the cause
of the error anymore. Obviously, it will do nothing if error is in your 
web-server configuration, so if I<Internal Server Error> message still remains, 
check your web-server configuration. Also, this package displays a stack trace 
when application dies. It is very useful in application development, so 
I<Eidolon::Debug> is included in applications by default.

This package doesn't depend on any other I<Eidolon> package, so you can use it
outside I<Eidolon> applications too.

While used, I<Eidolon::Debug> hooks global C<die> and C<warn> subroutines, so be
careful using other packages, that modify or depend on C<$SIG{"__DIE__"}> and
C<$SIG{"__WARN__"}> handlers.

=head1 METHODS

=head2 start_console()

Start a javascript debugging console. Prints a minimal HTTP header and javascript
code, so further error and warning messages could be displayed in nice-looking
form.

=head2 get_stack()

Get subroutine call stack. Returns reference to array of hashrefs, each hashref
stands for one level of the call stack. This hashref contains the following 
data:

=over 4

=item * package

Package name, where error has been occured.

=item * file

File name, where error has been occured.

=item * line

Line number, which caused program to die.

=item * sub

Subroutine name, where error has been occured.

=back

=head2 print_stack($stack)

Prints the call stack in nice preformatted table. C<$stack> - reference to
array of call stack hashrefs (result, returned by C<get_stack()> subroutine).

=head2 warn($message)

Custom warning handler. C<$message> - warning message to be displayed.

=head2 die($message)

Custom error handler. C<$message> - error message to be displayed. 

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Application>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut

__DATA__
<body>
<div id="eidolon-console" style="background-color: #F0F0F0; border: 1px solid #909090; position: absolute; top: 10px; left: 10px; width: 800px; font-family: Verdana, Tahoma; font-size: 12px; text-align: left;"></div>
<script>
    EidolonConsole = function ()
    {
        this.errors   = [];
        this.warnings = [];
        this.details  = 0;
    }

    EidolonConsole.prototype.addError = function (title, message, stack)
    {
        this.errors.push( { "title": title, "message": message, "stack": stack } );
        this.redraw();
    }

    EidolonConsole.prototype.addWarning = function (title, message)
    {
        this.warnings.push( { "title": title, "message": message } );
        this.redraw();
    }

    EidolonConsole.prototype.redraw = function ()
    {
        var obj, i, html, item, k, frame;

        obj = document.getElementById("eidolon-console");
        html = '<div id="eidolon-title" style="background-color: #7B84B0; color: white; padding: 10px; cursor: pointer;" onclick="eidolonDebug.toggleDetails();"><b>Eidolon::Debug</b> - ' + 
            this.errors.length + ' errors, ' + this.warnings.length + ' warnings</div>';

        html += '<div id="eidolon-details" style="display: none; padding: 10px; color: #606060;"></div>';

        obj.innerHTML = html;
        obj = document.getElementById("eidolon-details");
        html = "";

        for (i = 0; i < this.errors.length; i++)
        {
            item = this.errors[i];
            html += '<div style="border-left: 4px solid red; padding: 0 10px 0 10px; margin-bottom: 10px;"><b>' + item.title + ":</b> " + item.message + 
                    '<div style="font-size: 12px;"><pre>';
            
            for (k = 0; k < item.stack.length; k++)
            {
                frame = item.stack[k];

                if (frame)
                    html += frame.line + " " + frame.sub + " " + frame.file + "\n";
            }

            html += "</pre></div></div>";
        }

        for (i = 0; i < this.warnings.length; i++)
        {
            item = this.warnings[i];
            html += '<div style="border-left: 4px solid #7B84B0; padding: 0 10px 0 10px; margin-bottom: 10px;"><b>' + item.title + ":</b> " + item.message + "</div>";
        }

        obj.innerHTML = html;
    }

    EidolonConsole.prototype.toggleDetails = function ()
    {
        var obj = document.getElementById("eidolon-details");

        if (this.details)
        {
            this.details = 0;
            obj.style.display = "none";
        }
        else
        {
            this.details = 1;
            obj.style.display = "block";
        }
    }

    var eidolonDebug = new EidolonConsole();
</script>
