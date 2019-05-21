package MPMinus::Info; # $Id: Info.pm 277 2019-05-09 19:53:41Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Info - The mpminfo response handler

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    package MPM::Foo::Info;

    sub record {
        (
            -uri => '/mpminfo',
            -response => sub { shift->mpminfo() },
        )
    }

    1;

=head1 DESCRIPTION

This module provides mpminfo response handler

=head1 METHODS

=over 8

=item B<mpminfo>

    my $rc = $m->mpminfo();

The call in this notation returns info page and returns Apache RC

    my $info_struct = $m->mpminfo( 1 );

The call in notation with the true flag returns info page as perl-structure

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<mod_perl2>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = "1.00";

use Encode;

use Apache2::Const;
use Apache2::RequestRec;
use Apache2::RequestUtil;

use CTK::Util qw/ :FORMAT /;
use Data::Dumper;

use MPMinus::Util qw/getHiTime/;

sub mpminfo {
    my $self = shift;
    my $flag = shift || 0; # true - return as structure (table)
    my $r = $self->r;
    $r->subprocess_env unless exists $ENV{REQUEST_METHOD};

    # GENERAL DATA
    my $config      = $self->get_node('conf') // {};
    my $namespace   = $self->namespace();
    my $project = $config->{project} || "";
    my $name  = $config->{server_name} || "localhost";
    my $port = $config->{server_port} || 80;
    my %rplc = (
            'TITLE'     => sprintf("MPMinus v%s", $self->VERSION),
            'SUBTITLE'  => $project
                ? sprintf("%s (%s)", $project, ($port == 80) ? $name : sprintf("%s:%d", $name, $port))
                : "Oops. Project not found",
        );
    my %general = (
            "Namespace"         => $namespace,
            "LocalCount"        => $self->conf('package')->[1],
            "MPMinus version"   => $self->VERSION,
            "Apache version"    => $self->get_apache_version(),
            "Config file"       => $config->{fileconf},
            "Document root"     => $config->{document_root},
            "Modperl root"      => $config->{modperl_root},
            "Project name"      => $project,
            "Server name"       => $name,
            "Server port"       => $port,
            "Client remote address" => $config->{remote_addr},
        );

    # SUMMARY TABLE
    my %info = (
            general     => {%general},
            env         => {MPMinus::Info::Tools::get_env_info()},
            subproccess_env => {MPMinus::Info::Tools::get_subproccess_env($r)},
            mobject     => Dumper($self),
            ## Config
            controllers => {MPMinus::Info::Tools::get_controllers_info($self->disp())},
            config      => {MPMinus::Info::Tools::get_config_info($config)},
            ## Typeglobs
            typeglobs       => {MPMinus::Info::Tools::get_typeglobs_info($namespace)},
            typeglobs_mpm   => {MPMinus::Info::Tools::get_typeglobs_info("MPM")},
            typeglobs_main  => {MPMinus::Info::Tools::get_typeglobs_info()},
            ## callstack
            callstack   => {MPMinus::Info::Tools::get_callstack_info()},
            ## ISA
            isa_index   => {MPMinus::Info::Tools::get_isa_info($namespace.'::Index')},
            isa_handlers=> {MPMinus::Info::Tools::get_isa_info($namespace.'::Handlers')},
            isa_mpminus => {MPMinus::Info::Tools::get_isa_info('MPMinus')},
        );
    return %info if $flag;

    # RENDER
    my @buffer = ();
    push @buffer, dformat(_render_header(), {%rplc});
    push @buffer, _render_table_std(undef, {%general});
    push @buffer, _render_navbar();

    push @buffer, sprintf("<h2 id=\"ENVIRONMENT\">%s</h2>", "ENVIRONMENT (%ENV)");
    push @buffer, _render_table_std([qw/KEY VALUE/], $info{env});
    push @buffer, sprintf("<h3>%s</h3>", "SUBPROCESS ENVIRONMENT");
    push @buffer, _render_table_std([qw/KEY VALUE/], $info{subproccess_env});
    push @buffer, sprintf("<h2 id=\"MPMINUS\">%s</h2>", 'MPMINUS OBJECT ($m)');
    push @buffer, sprintf("<div class=\"box bg5\"><pre>%s</pre></div>", $info{mobject});

    push @buffer, sprintf("<h2 id=\"CONFIGURATION\">%s</h2>", "CONFIGURATION");
    push @buffer, _render_table_std([qw/KEY VALUE/], $info{config});

    push @buffer, sprintf("<h2 id=\"TYPEGLOBS\">%s</h2>", "TYPEGLOBS");
    push @buffer, _render_table_std(undef, $info{typeglobs});
    push @buffer, sprintf("<h3>%s</h3>", "MPM TYPEGLOBS");
    push @buffer, _render_table_std(undef, $info{typeglobs_mpm});
    push @buffer, sprintf("<h3>%s</h3>", "MAIN TYPEGLOBS");
    push @buffer, _render_table_std(undef, $info{typeglobs_main});

    push @buffer, sprintf("<h2 id=\"CALL-STACK\">%s</h2>", "CALL-STACK");
    push @buffer, _render_table_std([qw/DEPTH STACK/], $info{callstack});

    push @buffer, sprintf("<h2 id=\"ISA\">%s</h2>", "ISA");
    push @buffer, _render_table_std(undef, $info{isa_index});
    push @buffer, sprintf("<h3>%s</h3>", "ISA (Handlers)");
    push @buffer, _render_table_std(undef, $info{isa_handlers});
    push @buffer, sprintf("<h3>%s</h3>", "ISA (MPMinus)");
    push @buffer, _render_table_std(undef, $info{isa_mpminus});

    push @buffer, sprintf("<h2 id=\"LICENSE\">%s</h2>", "LICENSE");
    push @buffer, _render_license();

    push @buffer, sprintf("<p class=\"debug\">Processed in %.4f sec</p>", getHiTime() - $self->conf('hitime'));
    push @buffer, dformat(_render_footer(), {%rplc});

    # OUTPUT
    my $output = join("\n", @buffer);
    $r->content_type('text/html; charset=UTF-8');
    $r->headers_out->set('Content-Length', length(Encode::encode_utf8($output)) || 0);
    $r->print($output);
    $r->rflush();
    return Apache2::Const::OK;
}

sub _render_header {<<'HTML_END';
<!DOCTYPE html>
<html lang="en">
<head>
    <title>[SUBTITLE] | [TITLE]</title>
    <meta charset="utf-8" />
    <link rel="shortcut icon" href="data:image/vnd.microsoft.icon;base64,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">
    <!-- CSS -->
    <style>
        body {
            margin: 0 3rem;
            font-family: sans-serif;
            background-color: white;
        }
        @media (min-width: 60rem) {
            body {
                width: 55rem;
                margin: 0 auto;
            }
        }

        h1, h2, h3, h4 {
            text-align: left;
        }
        .clearfix::after {
            content: "";
            clear: both;
            display: table;
        }
        .header {
            margin-bottom: 1rem;
        }
        .subtitle {
            font-size: 125%;
        }
        .logo {
            display: inline-block;
            float: right;
            width: 4rem;
            height: 4rem;
            border: 0;
        }
        .navbar {
            margin-top: 1rem;
            font-size: 75%;
        }
        .footer {
            text-align: center;
            color: #999;
        }
        .undef {
            font-style: italic;
            color: #666;
        }
        .dig {
            color: #8c1717;
        }
        .debug {
            font-style: italic;
            color: #666;
            font-size: 75%;
            text-align: right;
        }
        pre {
            margin: 0;
            font-family: monospace;
            overflow-x: auto;
        }
        hr {
            background-color: #1b4113; /* bg1 */;
            border: 0;
            height: 1px;
        }

        a {
            color: navy;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }

        .bg1 {
            /*background-color: #7981d0;*/
            background-color: #1b4113; /* bg1 */
            color: #eee;
        }
        .bg2 {
            /*background-color: #d1c9ec;*/
            background-color: #3a7a41; /* bg2 */
        }
        .bg3 {
            /*background-color: #f6f4f5;*/
            background-color: #3db157; /* bg3 */
        }
        .bg4 {
            background-color: #abe1b2; /* bg4 */
        }
        .bg5 {
            background-color: #d3f2d5; /* bg5 */
        }

        small {
            font-style: italic;
        }
        small a {
            color: lime;
        }
        .small {
            font-size: 75%;
        }

        table {
            border: 0;
            border-collapse: collapse;
            width: 55rem;
            box-shadow: 1px 2px 3px #ccc;
        }
        th, td {
            border: 1px solid #666;
            vertical-align: baseline;
            padding: 3px 5px;
            max-width: 35rem;
            overflow-x: auto;
            font-size: 75%;
        }
        th {
            background-color: #3db157; /* bg3 */
        }
        td {
            background-color: #d3f2d5; /* bg5 */
        }
        th.w, td.w {
            width: 20rem;
            background-color: #abe1b2; /* bg4 */
        }
        .box {
            border: 1px solid #666;
            box-shadow: 1px 2px 3px #ccc;
            padding: 0.5rem;
            vertical-align: baseline;
        }
        .box::after {
            content: "";
            clear: both;
            display: table;
        }
        .box h1, .box h2, .box h3, .box h4 {
            margin: 0;
            padding: 0;
        }
    </style>
</head>
<body>
    <div class="box bg1 header">
        <a href="https://metacpan.org/release/MPMinus" title="MPMinus on meta::cpan"><img class="logo" alt="MPMinus Logo" src="data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgeG1sbnM6ZGM9Imh0dHA6Ly9wdXJsLm9yZy9kYy9lbGVtZW50cy8xLjEvIgogICB4bWxuczpjYz0iaHR0cDovL2NyZWF0aXZlY29tbW9ucy5vcmcvbnMjIgogICB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiCiAgIHhtbG5zOnN2Zz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciCiAgIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKICAgeG1sbnM6c29kaXBvZGk9Imh0dHA6Ly9zb2RpcG9kaS5zb3VyY2Vmb3JnZS5uZXQvRFREL3NvZGlwb2RpLTAuZHRkIgogICB4bWxuczppbmtzY2FwZT0iaHR0cDovL3d3dy5pbmtzY2FwZS5vcmcvbmFtZXNwYWNlcy9pbmtzY2FwZSIKICAgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgOTYgOTY7IgogICB2ZXJzaW9uPSIxLjEiCiAgIHZpZXdCb3g9IjAgMCA5NiA5NiIKICAgeG1sOnNwYWNlPSJwcmVzZXJ2ZSIKICAgaWQ9InN2ZzM3NjUiCiAgIHNvZGlwb2RpOmRvY25hbWU9ImxvZ29fd2hpdGUuc3ZnIgogICBpbmtzY2FwZTp2ZXJzaW9uPSIwLjkyLjQgKDVkYTY4OWMzMTMsIDIwMTktMDEtMTQpIj48bWV0YWRhdGEKICAgICBpZD0ibWV0YWRhdGEzNzcxIj48cmRmOlJERj48Y2M6V29yawogICAgICAgICByZGY6YWJvdXQ9IiI+PGRjOmZvcm1hdD5pbWFnZS9zdmcreG1sPC9kYzpmb3JtYXQ+PGRjOnR5cGUKICAgICAgICAgICByZGY6cmVzb3VyY2U9Imh0dHA6Ly9wdXJsLm9yZy9kYy9kY21pdHlwZS9TdGlsbEltYWdlIiAvPjxkYzp0aXRsZT48L2RjOnRpdGxlPjwvY2M6V29yaz48L3JkZjpSREY+PC9tZXRhZGF0YT48ZGVmcwogICAgIGlkPSJkZWZzMzc2OSIgLz48c29kaXBvZGk6bmFtZWR2aWV3CiAgICAgcGFnZWNvbG9yPSIjZmZmZmZmIgogICAgIGJvcmRlcmNvbG9yPSIjNjY2NjY2IgogICAgIGJvcmRlcm9wYWNpdHk9IjEiCiAgICAgb2JqZWN0dG9sZXJhbmNlPSIxMCIKICAgICBncmlkdG9sZXJhbmNlPSIxMCIKICAgICBndWlkZXRvbGVyYW5jZT0iMTAiCiAgICAgaW5rc2NhcGU6cGFnZW9wYWNpdHk9IjAiCiAgICAgaW5rc2NhcGU6cGFnZXNoYWRvdz0iMiIKICAgICBpbmtzY2FwZTp3aW5kb3ctd2lkdGg9IjEyNDEiCiAgICAgaW5rc2NhcGU6d2luZG93LWhlaWdodD0iNzY5IgogICAgIGlkPSJuYW1lZHZpZXczNzY3IgogICAgIHNob3dncmlkPSJmYWxzZSIKICAgICBpbmtzY2FwZTp6b29tPSI0LjM0Mzc1IgogICAgIGlua3NjYXBlOmN4PSIzOS40ODk5NzgiCiAgICAgaW5rc2NhcGU6Y3k9IjUyLjU2ODQzIgogICAgIGlua3NjYXBlOndpbmRvdy14PSIxNzA5IgogICAgIGlua3NjYXBlOndpbmRvdy15PSIyMDgiCiAgICAgaW5rc2NhcGU6d2luZG93LW1heGltaXplZD0iMCIKICAgICBpbmtzY2FwZTpjdXJyZW50LWxheWVyPSJzdmczNzY1Ij48aW5rc2NhcGU6Z3JpZAogICAgICAgdHlwZT0ieHlncmlkIgogICAgICAgaWQ9ImdyaWQ2MDI0IiAvPjwvc29kaXBvZGk6bmFtZWR2aWV3PjxzdHlsZQogICAgIHR5cGU9InRleHQvY3NzIgogICAgIGlkPSJzdHlsZTM3NDMiPgoJLnN0MHtkaXNwbGF5Om5vbmU7fQoJLnN0MXtkaXNwbGF5OmlubGluZTt9Cgkuc3Qye2ZpbGw6bm9uZTtzdHJva2U6IzQ1OUVEQjtzdHJva2Utd2lkdGg6MjtzdHJva2UtbGluZWNhcDpyb3VuZDtzdHJva2UtbGluZWpvaW46cm91bmQ7c3Ryb2tlLW1pdGVybGltaXQ6MTA7fQoJLnN0M3tkaXNwbGF5Om5vbmU7ZmlsbDpub25lO3N0cm9rZTojNDU5RURCO3N0cm9rZS13aWR0aDoyO3N0cm9rZS1saW5lY2FwOnJvdW5kO3N0cm9rZS1saW5lam9pbjpyb3VuZDtzdHJva2UtbWl0ZXJsaW1pdDoxMDt9Cgkuc3Q0e2ZpbGw6IzQ1OUVEQjt9Cjwvc3R5bGU+PGcKICAgICBjbGFzcz0ic3QwIgogICAgIGlkPSJHcmlkIgogICAgIHN0eWxlPSJkaXNwbGF5Om5vbmUiIC8+PGcKICAgICBpZD0iSG9tZSIKICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmUiIC8+PGcKICAgICBpZD0iU2VhcmNoIiAvPjxnCiAgICAgaWQ9IlBsdXMiCiAgICAgc3R5bGU9ImRpc3BsYXk6aW5saW5lIiAvPjxnCiAgICAgaWQ9Ik1pbnVzIgogICAgIGlua3NjYXBlOmxhYmVsPSJNaW51cyIKICAgICBzdHlsZT0iZGlzcGxheTppbmxpbmUiIC8+PGcKICAgICBpZD0iU2V0dGluZyIKICAgICBzdHlsZT0iZmlsbDpub25lO2ZpbGwtb3BhY2l0eToxIj48cGF0aAogICAgICAgY2xhc3M9InN0MiIKICAgICAgIGQ9Im0gODYsNDUuMyBjIDAuMSwyIDAuMSwzLjkgMCw1LjkgLTAuMiwyLjggMS4yLDUuNSAzLjYsNi44IGwgMC4yLDAuMSBjIDMuMiwxLjcgNC41LDUuNSAzLjEsOC45IHYgMCBjIC0xLjQsMy4zIC01LjEsNSAtOC41LDMuOSBsIC0wLjIsLTAuMSBjIC0yLjcsLTAuOCAtNS42LDAgLTcuNCwyLjEgLTEuMywxLjUgLTIuNywyLjggLTQuMiw0LjEgLTIuMSwxLjggLTMsNC43IC0yLjIsNy40IGwgMC4xLDAuMiBjIDEsMy40IC0wLjcsNy4xIC00LDguNSB2IDAgYyAtMy4zLDEuNCAtNy4yLDAgLTguOCwtMy4yIGwgLTAuMSwtMC4yIGMgLTEuMywtMi41IC00LC0zLjkgLTYuOCwtMy43IC0yLDAuMSAtMy45LDAuMSAtNS45LDAgLTIuOCwtMC4yIC01LjUsMS4yIC02LjgsMy42IEwgMzgsODkuOCBjIC0xLjcsMy4yIC01LjUsNC41IC04LjksMy4xIHYgMCBjIC0zLjMsLTEuNCAtNSwtNS4xIC0zLjksLTguNSBsIDAuMSwtMC4yIGMgMC44LC0yLjcgMCwtNS42IC0yLjEsLTcuNCAtMS41LC0xLjMgLTIuOCwtMi43IC00LjEsLTQuMiAtMS44LC0yLjEgLTQuNywtMyAtNy40LC0yLjIgbCAtMC4yLDAuMSBjIC0zLjQsMSAtNy4xLC0wLjcgLTguNSwtNCB2IDAgQyAxLjYsNjMuMiAzLDU5LjMgNi4yLDU3LjcgbCAwLjIsLTAuMSBjIDIuNSwtMS4zIDMuOSwtNCAzLjcsLTYuOCAtMC4xLC0yIC0wLjEsLTMuOSAwLC01LjkgMC4yLC0yLjggLTEuMiwtNS41IC0zLjYsLTYuOCBMIDYuMywzOCBDIDMuMSwzNi4zIDEuOCwzMi41IDMuMiwyOS4xIHYgMCBjIDEuNCwtMy4zIDUuMSwtNSA4LjUsLTMuOSBsIDAuMiwwLjEgYyAyLjcsMC44IDUuNiwwIDcuNCwtMi4xIDEuMywtMS41IDIuNywtMi44IDQuMiwtNC4xIDIuMSwtMS44IDMsLTQuNyAyLjIsLTcuNCBsIC0wLjEsLTAuMiBjIC0xLC0zLjQgMC43LC03LjEgNCwtOC41IHYgMCBjIDMuMywtMS40IDcuMiwwIDguOCwzLjIgbCAwLjEsMC4yIGMgMS4zLDIuNSA0LDMuOSA2LjgsMy43IDIsLTAuMSAzLjksLTAuMSA1LjksMCBDIDU0LDEwLjMgNTYuNyw4LjkgNTgsNi41IEwgNTguMSw2LjMgQyA1OS44LDMuMSA2My42LDEuOCA2NywzLjIgdiAwIGMgMy4zLDEuNCA1LDUuMSAzLjksOC41IGwgLTAuMSwwLjIgYyAtMC44LDIuNyAwLDUuNiAyLjEsNy40IDEuNSwxLjMgMi44LDIuNyA0LjEsNC4yIDEuOCwyLjEgNC43LDMgNy40LDIuMiBsIDAuMiwtMC4xIGMgMy40LC0xIDcuMSwwLjcgOC41LDQgdiAwIGMgMS40LDMuMyAwLDcuMiAtMy4yLDguOCBsIC0wLjIsMC4xIGMgLTIuNSwxLjMgLTMuOSw0IC0zLjcsNi44IHoiCiAgICAgICBpZD0icGF0aDM3NTAiCiAgICAgICBpbmtzY2FwZTpjb25uZWN0b3ItY3VydmF0dXJlPSIwIgogICAgICAgc3R5bGU9ImRpc3BsYXk6aW5saW5lO2ZpbGw6IzFiNDExMztmaWxsLW9wYWNpdHk6MTtzdHJva2U6IzQ1OWVkYjtzdHJva2Utd2lkdGg6MjtzdHJva2UtbGluZWNhcDpyb3VuZDtzdHJva2UtbGluZWpvaW46cm91bmQ7c3Ryb2tlLW1pdGVybGltaXQ6MTAiCiAgICAgICBpbmtzY2FwZTpsYWJlbD0icGF0aDM3NTAiIC8+PHJlY3QKICAgICAgIHN0eWxlPSJvcGFjaXR5OjAuOTAyMDAwNDtmaWxsOiNmZmZmZmY7ZmlsbC1vcGFjaXR5OjE7c3Ryb2tlOiM0NTllZGI7c3Ryb2tlLXdpZHRoOjEuNzkxNzM0ODE7c3Ryb2tlLWxpbmVqb2luOnJvdW5kO3N0cm9rZS1taXRlcmxpbWl0OjEwO3N0cm9rZS1kYXNoYXJyYXk6bm9uZTtzdHJva2Utb3BhY2l0eToxIgogICAgICAgaWQ9InJlY3Q0NTgwIgogICAgICAgd2lkdGg9IjU0LjAyNzg4OSIKICAgICAgIGhlaWdodD0iMTUuMjMwMjE0IgogICAgICAgeD0iMjAuOTcyMTExIgogICAgICAgeT0iNDAuNzY5Nzg3IgogICAgICAgcnk9IjAuOTg5MDEwOTMiIC8+PC9nPjxnCiAgICAgaWQ9IlBlb3BsZSIgLz48ZwogICAgIGlkPSJTdGF0aXN0aWMiIC8+PGcKICAgICBpZD0iTGVmdF9BcnJvdyIgLz48ZwogICAgIGlkPSJSaWdodF9BcnJvdyIgLz48ZwogICAgIGlkPSJVcF9BcnJvdyIgLz48ZwogICAgIGlkPSJCb3R0b21fQXJyb3ciIC8+PGcKICAgICBpZD0iQXR0YWNobWVudCIgLz48ZwogICAgIGlkPSJDYWxlbmRhciIgLz48ZwogICAgIGlkPSJQcmljZSIgLz48ZwogICAgIGlkPSJOZXdzIiAvPjwvc3ZnPg==" /></a>
        <h1>[TITLE]</h1>
        <div class="subtitle">[SUBTITLE]</div>
    </div>
HTML_END
}
sub _render_navbar {<<'HTML_END';
<div class="box bg5 navbar">
    <a href="#ENVIRONMENT" title="ENVIRONMENT (%ENV)">ENVIRONMENT</a>
    &nbsp;|&nbsp;
    <a href="#MPMINUS" title="MPMINUS OBJECT ($m)">MPMINUS</a>
    &nbsp;|&nbsp;
    <a href="#CONFIGURATION" title="CONFIGURATION">CONFIGURATION</a>
    &nbsp;|&nbsp;
    <a href="#TYPEGLOBS" title="TYPEGLOBS">TYPEGLOBS</a>
    &nbsp;|&nbsp;
    <a href="#CALL-STACK" title="CALL-STACK">CALL-STACK</a>
    &nbsp;|&nbsp;
    <a href="#ISA" title="ISA">ISA</a>
    &nbsp;|&nbsp;
    <a href="#LICENSE" title="LICENSE">LICENSE</a>
</div>
HTML_END
}
sub _render_footer {<<'HTML_END';
    <p>&nbsp;</p>
    <div class="box bg1">
        <div class="footer">
            <small>Copyright &copy; 1998-2019 D&amp;D Corporation. All Rights Reserved</small>
        </div>
    </div>
</body>
</html>
HTML_END
}
sub _render_license {<<'HTML_END';
<div class="box bg5 small">
    <p>
        This program is free software; you can redistribute it and/or
        modify it under the same terms as Perl itself.
    </p>
    <p>
        See <a href="https://dev.perl.org/licenses" title="LICENSE">https://dev.perl.org/licenses</a>
    </p>
</div>
HTML_END
}
sub _render_table_std {
    my ($head, $data) = @_; # Headers-array, Data-hash
    my @tr = ();

    # Headers
    if ($head && ref($head) eq "ARRAY") {
        my @th = ();
        foreach my $h (@$head) {
            push @th, sprintf("<th>%s</th>", tag($h));
        }
        push @tr, sprintf("<tr>\n%s\n</tr>", join("\n", @th));
    }

    # Data
    foreach my $k (sort {$a cmp $b} keys %$data) {
        my ($class, $v);
        if (!defined($data->{$k})) {
            $v = "no value";
            $class = "undef";
        } elsif (ref($data->{$k})) {
            $class = "pre";
            $v = tag(Dumper($data->{$k}));
        } elsif ($data->{$k} =~ /^[+\-]?[0-9.]+$/ ) {
            $class = "dig";
            $v = tag($data->{$k});
        } else {
            $v = tag($data->{$k});
        }
        $v =~ s/\n+/<br \/>/gs;
        my @td = (sprintf("<td class=\"w\">%s</td>", tag($k)));
        if ($class && $class eq "pre") {
            push @td, sprintf("<td><pre>%s</pre></td>", $v);
        } elsif ($class) {
            push @td, sprintf("<td class=\"%s\">%s</td>", $class, $v);
        } else {
            push @td, sprintf("<td>%s</td>", $v);
        }
        push @tr, sprintf("<tr>\n%s\n</tr>", join("\n", @td));
    }

    # Out
    return sprintf("<table>\n%s\n</table>", join("\n", @tr));
}

1;

package MPMinus::Info::Tools;
use strict;

use vars qw($VERSION @EXPORT_OK);
$VERSION = "1.00";

use APR::Table ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Try::Tiny;

use base qw /Exporter/;

@EXPORT_OK = qw/
        get_typeglobs_info
        get_callstack_info
        get_isa_info
        get_env_info
        get_subproccess_env
        get_config_info
        get_controllers_info
    /;

sub get_typeglobs_info {
    my $f = shift || 'main';
    no strict "refs";
    my %outh;

    foreach (sort keys %{"$f\:\:"}) {
        my $k = $_;
        my $v = ${"$f\:\:"}{$_};
        $outh{$k} = $v if defined($v) && $_ =~ /^\w/;
    }

    return %outh
}
sub get_callstack_info {
    my %outh;
    my $j = 0;
    my @args;

    while (@args = caller($j++)) {
        $outh{'#'.$j} = join("\n",map {$_ = defined($_) ? $_ : ''} @args[0..3]);
    }

    return %outh
}
sub get_isa_info {
    my $package = shift || 'main';
    my %outh;
    my $j = 0;
    no strict 'refs';
    foreach (@{"$package\:\:ISA"}) {
        $outh{'#'.(++$j)} = $_;
    }
    return %outh;
}
sub get_env_info {
    my %outh;
    foreach my $key (sort(keys(%ENV))) {
        my $val = $ENV{$key};
        $val =~ s|\n|\\n|g;
        $val =~ s|"|\\"|g;
        $outh{$key} = $val;
    }
    return %outh;
}
sub get_subproccess_env {
    my $r = shift || Apache2::RequestUtil->request;
    my $table = $r->subprocess_env();
    my %outh;
    foreach my $key (keys %{$table}) {
        my $val = $table->{$key};
        $val =~ s|\n|\\n|g;
        $val =~ s|"|\\"|g;
        $outh{$key} = $val;
    }
    return %outh;
}
sub get_config_info {
    my $lconf = shift || return ();
    my %outh;

    my %conf = %$lconf;
    foreach my $k (keys %conf) {
        my $v = $conf{$k};
        if (defined($v) && ref($v) eq "ARRAY") {
            $outh{$k} = "[" . join(", ", @$v) . "]";
        } else {
            $outh{$k} = $v;
        }
    }
    return %outh;
}
sub get_controllers_info {
    my $dispo = shift;
    my $records = $dispo->{records};
    my %ret;
    foreach my $k (grep {$_ ne 'default'} keys %$records) {
        my $rec = $dispo->get($k);
        my $ctp = $rec->{type};
        if ($ctp eq 'location') {
            if ($k eq '/') {
                $ret{'location:root'} = $k;
            } else {
                $ret{'location:'.$k} = $k;
            }
        } else {
            my $params = $rec->{params};
            my $paramsv = $params->{$ctp} ? $params->{$ctp} : 'undefined';
            my $v = $paramsv && ref($paramsv) eq 'ARRAY' ? $paramsv->[0] : $paramsv;
            $ret{lc($ctp.':'.$k)} = ref($v) ? "/$k" : $v;
        }
    }
    return %ret;
}

1;
