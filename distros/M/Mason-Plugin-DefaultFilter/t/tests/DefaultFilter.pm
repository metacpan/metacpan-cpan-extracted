package tests::DefaultFilter;

use Test::Class::Most parent => 'Mason::Test::Class';

sub before : Test(setup) {
    my $self = shift;

    $self->setup_interp(
        plugins                => ['DefaultFilter'],
        default_filters        => ['NoBlankLines','Trim'],
        no_source_line_numbers => 1,
    );
}

sub test_defaultfilter : Test(1) {
    my $self = shift;

    $self->test_comp(
        src  => <<'EOF',
<%class>
my $foo = <<'EOT';
          
      
                
    Now is the time for all good men                           
                       

EOT
</%class>

<% $foo %> to come to the aid of their country

<% $foo |N %> to come to the aid of their country
EOF
        expect => <<'EOF',
Now is the time for all good men to come to the aid of their country

          
      
                
    Now is the time for all good men                           
                       

 to come to the aid of their country
EOF
    );
}

1;
