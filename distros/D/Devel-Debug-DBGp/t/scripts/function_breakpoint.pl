package foo;

sub sub_break {
    1; # we need a line here
}

package main;

sub sub_break {
    1; # we need a line here
}

sub return_break {
    1; # we need a line here
}

eval <<'EOT';
sub bar::sub_break {
    1; # we need a line here
}
EOT

foo::sub_break();
main::sub_break();
main::return_break();
bar::sub_break();
bar::sub_break();
main:sub_break();

1; # to avoid the program exiting
