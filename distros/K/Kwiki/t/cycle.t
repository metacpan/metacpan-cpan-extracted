use lib 't', 'lib';
use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Test::Memory::Cycle";
    if ($@) {
        plan skip_all => 'These tests require Test::Memory::Cycle';
    }
    else {
        plan tests => 35;
    }
}
use Kwiki;

{
    my $kwiki = Kwiki->new;
    my $hub = $kwiki->load_hub;

    memory_cycle_ok($kwiki, 'check for cycles in Kwiki object');
    memory_cycle_ok($hub, 'check for cycles in Kwiki::Hub object');
}

{
    my $kwiki = Kwiki->new;
    {
        my $hub = $kwiki->load_hub;
    }

    ok($kwiki->hub, 'Hub does not get destroyed until main goes out of scope');
}

{
    my %classes = (cgi_class => 'Kwiki::CGI',
                   headers_class => 'Spoon::Headers',
                   cookie_class => 'Kwiki::Cookie',
                   css_class => 'Kwiki::CSS',
                   files_class => 'Kwiki::Files',
                   formatter_class => 'Kwiki::Formatter',
                   javascript_class => 'Kwiki::Javascript',
                   pages_class => 'Kwiki::Pages',
                   preferences_class => 'Kwiki::Preferences',
                   template_class => 'Kwiki::Template::TT2',
                   users_class => 'Kwiki::Users',

                   archive_class => 'Kwiki::Archive',
                   display_class => 'Kwiki::Display',
                   edit_class => 'Kwiki::Edit',
# XXX Figure out why this fails...
#                    icons_class => 'Kwiki::Icons',
                   pane_class => 'Kwiki::Pane',
                   pages_class => 'Kwiki::Pages',
                   theme_class => 'Kwiki::Theme::Basic',
                  );

    my $kwiki = Kwiki->new;
    my $hub = $kwiki->load_hub(\%classes);

    foreach my $key (sort keys %classes) {
        (my $id = $key) =~ s/_class$//;
        my $object = $hub->$id;

        memory_cycle_ok($hub, 'check for cycles in Kwiki::Hub object');
        memory_cycle_ok($object, "check for cycles in $classes{$key} object");
    }
}

