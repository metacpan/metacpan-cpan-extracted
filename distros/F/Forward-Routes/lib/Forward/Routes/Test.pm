## ---------------------------------------------------------------------------
##  Testing
## ---------------------------------------------------------------------------

sub test {
    my $self = shift;
    my ($name, $request, $expected_matches) = @_;

    my ($method, $path) = %$request;

    my $matches = $self->match($method => $path);


    # compare number of match
    my $number_of_matches          = defined $matches ? @$matches : 0;
    my $number_of_expected_matches = defined $expected_matches ? @$expected_matches : 0;

    my $equal_matches = Test::More::is($number_of_matches, $number_of_expected_matches);
    $equal_matches || Test::More::diag('number of matches not equal to number of expected matches');


    # compare params for each match if number of matches equal to number of expected matches
    SKIP: {
        Test::More::skip("", 1) if !$equal_matches;

        for (my $i=0; $i<$number_of_matches; $i++) {
            my $match_params          = $matches->[$i]->params;
            my $expected_match_params = $expected_matches->[$i];
    
            Test::More::is_deeply($match_params => $expected_match_params);
        }
    }

    my %params = $expected_matches && $expected_matches->[-1] ? %{$expected_matches->[-1]} : ();

    Test::More::is($self->build_path($name, %params)->{path}, $path);
    Test::More::is($self->build_path($name, %params)->{method}, $method);

}
