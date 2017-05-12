package Eidolon::Error;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Error.pm - system-wide error handler
#
# ==============================================================================

use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-12 06:23:39

# ------------------------------------------------------------------------------
# error($exception)
# error handler
# ------------------------------------------------------------------------------
sub error 
{
    my ($r, $exception, $file, $line, $query, $type);
    
    $exception  = shift;
    $file       = $exception->file;
    $line       = $exception->line;

    $r          = Eidolon::Core::Registry->get_instance;
    $type       = ref $exception;

    $r->cgi->send_header;

    print << "EOT";
<html>
    <head>
        <title>Eidolon</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    </head>
    <body>
        <style type="text/css">
            body {
                margin: 0px;
                padding: 0px;
                text-align: center;
                background-color: #FFF;
            }

            div#window {
                width: 800px;
                height: 100%;
                background-color: #F0F0F0;
            }

            div#content {
                width: 100%;
                font-size: 9pt;
                font-family: Verdana, Tahoma;
                text-align: left;
                color: #606060;
                padding: 15px 15px 15px 15px;
                -moz-box-sizing: border-box;
            }

            h1 {
                font-size: 16pt;
                margin-top: 0;
                text-transform: lowercase;
                font-weight: normal;
                border-bottom: 1px dashed #606060;
                padding-bottom: 5px;
            }
        </style>
        <center>
            <div id="window">
                <div id="content">
                    <h1>software error</h1>
                    <p>$exception</p>

                    <ul>
                        <li>Exception: <em>$type</em></li>
                        <li>File: <em>$file</em></li>
                        <li>Line: <em>$line</em></li>
                    </ul>

                    <br /><br />
                </div>
            </div>
        </center>
    </body>
</html>
EOT
}

1;

__END__

=head1 NAME

Eidolon::Error - system-wide error handler.

=head1 DESCRIPTION

The I<Eidolon::Error> package is used as default error handler for all
I<Eidolon> applications. It is called when an error occurs during 
request handling and no application-specific error handler is defined in
configuration. 

=head1 METHODS

=head2 error($exception)

Error handler. Displays an error message and some diagnostic information.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Application>, L<Eidolon::Core::Config>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
