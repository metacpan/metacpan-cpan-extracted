package MPMinus::Debug::Info; # $Id: Info.pm 151 2013-05-29 14:31:19Z minus $
use strict;

=head1 NAME

MPMinus::Debug::Info - mpminfo methods

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    sub record {
        (
            -uri => '/',
            -response => sub { shift->mpminfo() },
        )
    }

=head1 DESCRIPTION

The main module provides debugging methods

=head1 METHODS

=over 8

=item B<mpminfo>

    $m->mpminfo();
    $m->mpminfo( $template_url );

Method mpminfo returns info page

=back

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION);
$VERSION = 1.00;

use Apache2::Const;
use CGI();
use CTK::Util qw/ :API /;
use TemplateM;
use Data::Dumper;
use MPMinus::Debug::System;

sub mpminfo {
    my $m = shift;
    my $url = shift;
    my $r = $m->r;
    my %h = ();
    my $q = new CGI;
    my %usr = ();
    foreach ($q->all_parameters) {
        $usr{$_} = $q->param($_);
        Encode::_utf8_on($usr{$_});
    }
    my $urlshtml = $m->conf('url_shtml');
    my $turl = $urlshtml.'/'.$m->conf('file_mpminfo');
    my ($status, $password);
    ($status, $password) = $r->get_basic_auth_pw if $r->user();
    my $template = new TemplateM( 
            -url    => $url || $turl, 
            -user   => $r->user() || '',
            -pass   => defined($password) ? $password : '',
            -utf8   => 1,
        );
        
    # STEP 1. GENERAL DATA
    my $gcfg   = $m->get_node('conf');
    my $whoiam = $m->namespace();
    $template->stash($gcfg);
    $h{whoiam}     = $whoiam;
    $h{curpackage} = scalar(__PACKAGE__);
    $h{localcount} = $m->conf('package')->[1];
    $h{mobject}    = Dumper($m);

    # STEP 2. CONFIGURATION AND META DATA
    _table_std($template, controllers => {controllers_info($m->disp())});
    _table_std($template, cfgdata     => {config_info($gcfg)});
    _table_std($template, metadata    => {metadata_info(catfile($m->conf('document_root'),'META.yml'))});

    # STEP 4. TYPEGLOBS, CALLSTACK, ISA, ENVIRONMENTS (ENV, USR)
    _table_std($template, typeglobs2  => {typeglobs_info($whoiam)});
    _table_std($template, typeglobs1  => {typeglobs_info('MPM')});
    _table_std($template, typeglobs0  => {typeglobs_info()});
    _table_std($template, callstack   => {callstack_info()});
    _table_std($template, isa2        => {isa_info($whoiam.'::Index')});
    _table_std($template, isa1        => {isa_info($whoiam.'::Handlers')});
    _table_std($template, isa0        => {isa_info('MPMinus')});
    _table_std($template, envdata     => {env_info()});
    _table_std($template, usrdata     => \%usr);

    # OUTPUT
    $template->stash(\%h);
    my $output = $template->output();
    croak("Template \"$turl\" not found!") unless $output;
    $r->content_type('text/html; charset=UTF-8');
    my $len = length(Encode::encode_utf8($output)) || 0;
    $r->headers_out->set('Content-Length', $len);
    $r->print($output);
    $r->rflush();
    return Apache2::Const::OK;
}

sub _table_std {
    my ($t,$block,$rhash) = @_;
    
    my $cfg_box = $t->start($block);
    foreach my $k (sort {$a cmp $b} keys %$rhash) {
        my $v = defined($rhash->{$k}) ? $rhash->{$k} : '';
        my $class = ($v =~ /^[+\-]?\d+$/) ? 'integer' : 'string';
        $cfg_box->loop(
            name  => $k,
            value => ref($v) ? Dumper($v) : $v,
            class => $class,
        );
    }
    $cfg_box->finish;
}

1;
