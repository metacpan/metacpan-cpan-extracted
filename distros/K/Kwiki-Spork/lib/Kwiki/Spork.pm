package Kwiki::Spork;
use Kwiki::Plugin -Base;
use Kwiki::Installer -Base;
our $VERSION = '0.11';

const class_id => 'spork';

sub register {
    my $registry = shift;
    $registry->add(wafl => spork => 'Kwiki::Spork::Wafl');
}

package Kwiki::Spork::Wafl;
use base 'Spoon::Formatter::WaflBlock';
use Cwd;

sub to_html {
    my $text = $self->block_text;
    $self->make_spork($text);
    return join '',
      qq{<div class="spork">\n},
      $self->render($text),
      qq{</div>\n};
}

sub make_spork {
    my $home = cwd;
    my $text = shift;
    my $page = $self->hub->pages->current;
    my $spork_dir = io->catdir(
        $self->hub->spork->plugin_directory, $page->id)->assert;
    if ((my @x = $spork_dir->all) == 0) {
        $self->require_spork;
        chdir $spork_dir;        
        $self->spork_command->new_spork;
        chdir $home;
    }
    my $slides = io->catfile("$spork_dir", 'Spork.slides');
    unless (-f $slides->name and $slides->scalar eq $text) {
        $self->require_spork;
        $slides->print($text);
        $slides->close;
        chdir $spork_dir;        
        my %env = %ENV;
        delete $env{GATEWAY_INTERFACE}; #XXX Ugly
        local %ENV = %env;
        $self->spork_command->make_spork;
        chdir $home;
        my $htaccess = io('template/tt2/spork_htaccess')->scalar;
        io("$spork_dir/slides/.htaccess")->print($htaccess);
    }
}

sub spork_command {
    local $main::HUB; #XXX tt2 hack
    Spork->new->load_hub->command;
}

sub render {
    my $text = shift;
    $text =~ s/^\+//gm;
    $text = join "----\n", grep {
        /\S/ and not /^\w+:\s+\S+/
    } split /^\-{4,}\s*\n/m, $text;
    $self->hub->template->process('spork_section.html',
        text => $text,
    );
}

#XXX Something evil is happening and I need this ugly hack.
sub require_spork { 
    require Spork;
    require Spork::Config;
    require Spork::Hub;
    require Spork::Command;
    require Spork::Template::TT2;
    require Spork::Formatter;
    require Spork::Slides;
}

package Kwiki::Spork;
__DATA__

=head1 NAME 

Kwiki::Spork - Kwiki Spork Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/spork_htaccess__
Allow from all
__template/tt2/spork_section.html__
<div class="spork">
<p>
<a target="spork" href="plugin/spork/[% hub.pages.current.id %]/slides/start.html">Start Spork Slideshow</a>
</p>
<hr />
[% hub.formatter.text_to_html(text) %]
</div>
