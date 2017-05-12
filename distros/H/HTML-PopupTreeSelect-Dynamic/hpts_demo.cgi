#!/usr/bin/perl -w
use strict;
require '/home/sam/module-dev/HTML-PopupTreeSelect-Dynamic/Dynamic.pm';
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use File::Find;
use File::Spec::Functions qw(canonpath rel2abs);
use HTML::Template;

my $query = CGI->new();
print $query->header;
my $select = build_select();

if (not $query->param('rm') or $query->param('rm') eq 'show') {
    my $template = HTML::Template->new(filename => 'hpts_demo.tmpl', 
                                       associate => $query);
    $template->param(select => $select->output);
    print $template->output;
} elsif ($query->param('rm') eq 'get_node') {
    print $select->handle_get_node(query => $query);
} else {
    die "Unknown mode!";
}
exit;

sub build_select {
    # build a tree using directory data from the Bricolage project lib tree
    my $data = { label => 'root',
                 value => '0',
                 children => [],
                 open => 1,
               };
    for my $one (0 .. 9) {
        my $sub;
        push (@{$data->{children}}, $sub = { label => $one,
                                             value => $one,
                                             children => [] });

        for my $two (0 .. 9) {
            my $sub2;
            push(@{$sub->{children}}, $sub2 = { label => "$one.$two",
                                                value => "$one.$two",
                                                children => [] });
            my $sub3;
            for my $three (0 .. 9) {
                push(@{$sub2->{children}}, $sub3 = { label => "$one.$two.$three",
                                                     value => "$one.$two.$three",
                                                     children => [] });
                for my $four (0 .. 19) {
                    push(@{$sub3->{children}}, { label => "$one.$two.$three.$four",
                                                 value => "$one.$two.$three.$four", });
                }
            }
        }
    }
            
    # build select
    my $select = HTML::PopupTreeSelect::Dynamic->new(name => 'ca',
                                            data => $data,
                                            title => 'Select a Directory',
                                            button_label => 
                                            'Choose a Directory',
                                            onselect   => 'alert',
                                            width => 250,
                                            resizable => 0,
                                            image_path => './images/',
                                            height=> 300,
                                            scrollbars => 1,
                                            hide_selects=> 1,
                                            dynamic_params => "rm=get_node",
                                           );
    
    return $select;
}
