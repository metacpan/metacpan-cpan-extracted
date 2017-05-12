use Test::More qw(no_plan);
use_ok('HTML::PopupTreeSelect');

my $data = { label    => "Root",
             value    => 'val0',
             children => [
                          { label    => "Top Category 1",
                            value       => 'val1',
                            children => [
                                         { label => "Sub Category 1",
                                           value    => 'val2'
                                         },
                                         { label => "Sub Category 2",
                                           value    => 'val3'
                                         },
                                        ],
                          },
                          { label  => "Top Category 2",
                              value     => 'val4',
                          },
                         ],
           };

my $select = HTML::PopupTreeSelect->new(name => 'category',
                                        data => $data,
                                        title => 'Select a Category',
                                        button_label => 'Choose');
isa_ok($select, 'HTML::PopupTreeSelect');

my $output = $select->output();
ok($output);

# see if all the labels made it
for ("Root","Top Category 1", "Sub Category 1",
     "Sub Category 2", "Top Category 2") {
    like($output, qr/$_/);
}

# see if all the values made it
for (0 .. 4) {
    like($output, qr/val$_/);
}

# this one should have CSS
like($output, qr/text\/css/);

# add a second layer
$data = [{ label    => "Root 2",
           value    => 'val5',
           children => [
                        { label => "Top Category 3",
                          value => 'val6'
                        }
                       ]
	 }, $data,
        ];

# test modifying template src, and use of parent
$HTML::PopupTreeSelect::TEMPLATE_SRC =~
    s{<tmpl_var label>}
     {<tmpl_var label> (<tmpl_loop parent><tmpl_var label></tmpl_loop>)};

# make one without CSS
my $nocss = HTML::PopupTreeSelect::DummySub->new(name => 'category',
                                       data => $data,
                                       title => 'Select a Category',
                                       button_label => 'Choose',
                                       parent_var => 1,
                                       include_css => 0);
isa_ok($nocss, 'HTML::PopupTreeSelect::DummySub');
my $nocss_output = $nocss->output;
ok($nocss_output);
ok($nocss_output !~ qr/text\/css/);

# let's look for the parent labels, three levels deep
for my $first (@$data) {
    my $label1 = $first->{label};
    like($nocss_output, qr/\Q$label1 ()/);

    for my $second (@{$first->{children}}) {
        my $label2 = $second->{label};
        like($nocss_output, qr/\Q$label2 ($label1)/);

        for my $third (@{$second->{children}}) {
            my $label3 = $third->{label};
            like($nocss_output, qr/\Q$label3 ($label2)/);
        }

    }

}

# see if all the values made it (we increment them in subclass method)
for (1 .. 7) {
    like($nocss_output, qr/val$_/);
}

# test subclassing
package HTML::PopupTreeSelect::DummySub;

use base 'HTML::PopupTreeSelect';

sub _output_node {
    my ($self, %arg) = @_;

    my @nodes;
    if (ref $arg{node} eq 'ARRAY') {
        push @nodes, @{$arg{node}};
    } else {
        @nodes = ($arg{node});
    }

    # increment for the heck of it
    $_->{value}++ for @nodes;

    $self->SUPER::_output_node(%arg);
}
