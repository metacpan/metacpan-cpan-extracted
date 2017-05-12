use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'HTML::Template::Expr',
    'VERSION_FROM'	=> 'Expr.pm',
    'PREREQ_PM'		=> {
                            'HTML::Template'    => '2.4',
                            'Parse::RecDescent' => 0,
                            'Text::Balanced'    => 0,
			    'Test::More'        => 0,
                           },
    'ABSTRACT_FROM'     => 'Expr.pm',
    'AUTHOR'            => 'Sam Tregar <sam@tregar.com>',
);
