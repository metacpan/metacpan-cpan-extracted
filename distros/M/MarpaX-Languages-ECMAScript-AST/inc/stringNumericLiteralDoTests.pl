my $ecmaAst = MarpaX::Languages::ECMAScript::AST->new('StringNumericLiteral' => { semantics_package => $impl});
my $stringNumericLiteral = $ecmaAst->stringNumericLiteral;

our $EPSILON = 1.0E-6;

sub stringNumericLiteralDoTests::is_nan     { return $impl->new(number => $_[0])->is_nan }
sub stringNumericLiteralDoTests::is_inf     { return $impl->new(number => $_[0])->is_inf }
sub stringNumericLiteralDoTests::is_zero    { return stringNumericLiteralDoTests::is_equal($_[0], 0) }
sub stringNumericLiteralDoTests::is_pos_one { return stringNumericLiteralDoTests::is_equal($_[0], 1) }
sub stringNumericLiteralDoTests::is_equal   { return (abs($_[0] - $_[1]) < $EPSILON) }

my %DATA = (
    'ff'         => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_nan($rc), 'input: "ff"' . "=> $rc")},
    '09'         => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 9), 'input: "09"' . "=> $rc")},
    '+09'        => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 9), 'input: "+09"' . "=> $rc")},
    '-000000009' => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, -9), 'input: "-000000009"' . "=> $rc")},
    '          ' => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_zero($rc), 'input: "          "' . "=> $rc")},
    "    \n    " => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_zero($rc), 'input: "    \n    "' . "=> $rc")},
    '123.85'     => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 123.85), 'input: "123.85"' . "=> $rc")},
    '0123.85'    => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 123.85), 'input: "0123.85"' . "=> $rc")},
    '0123.085'   => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 123.085), 'input: "0123.085"' . "=> $rc")},
    '0123.0850'  => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 123.0850), 'input: "0123.0850"' . "=> $rc")},
    '$123.85'    => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_nan($rc), 'input: "$123.85"' . "=> $rc")},
    'three'      => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_nan($rc), 'input: "three"' . "=> $rc")},
    '0xFF'       => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 0xFF), 'input: "0xFF"' . "=> $rc")},
    '3.14'       => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 3.14), 'input: "3.14' . "=> $rc")},
    '0.0314E+02' => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 3.14), 'input: "0.0314E+02"' . "=> $rc")},
    '.0314E+02'  => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 3.14), 'input: ".0314E+02"' . "=> $rc")},
    '314.E-2'    => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 3.14), 'input: "314.E-2"' . "=> $rc")},
    '314.E-0002' => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 3.14), 'input: "314.E-0002"' . "=> $rc")},
    '00314.E-02' => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_equal($rc, 3.14), 'input: "00314.E-02"' . "=> $rc")},
    " 1.0 "      => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_pos_one($rc), 'input: " 1.0 "' . "=> $rc")},
    ""           => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_zero($rc), 'input: ""' . "=> $rc")},
    "Infinity"   => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_inf($rc), 'input: "Infinity"' . "=> $rc")},
    "+Infinity"  => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_inf($rc), 'input: "+Infinity"' . "=> $rc")},
    "-Infinity"  => sub {my $rc = shift; ok(stringNumericLiteralDoTests::is_inf($rc), 'input: "-Infinity"' . "=> $rc")},
    );
foreach (keys %DATA) {
    my $value;
    if (length("$_") <= 0) {
	$value = $impl->new->pos_zero->host_value;
    } else {
	eval{
	    my $parse = $stringNumericLiteral->{grammar}->parse("$_",
								$stringNumericLiteral->{impl});
	    $value = $stringNumericLiteral->{grammar}->value($stringNumericLiteral->{impl});
	};
        if ($@) {
            $value = $impl->new->nan->host_value;
        }
    }
    $DATA{$_}($value);
}

done_testing(2 + scalar(keys %DATA));
