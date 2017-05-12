# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################


use Test::More tests => 6;

BEGIN{
    use_ok('HTML::DBForm');
    use_ok('HTML::DBForm::Search');
}

#########################

my $editor = HTML::DBForm->new( 
    table           => 'test', 
    primary_key     => 'test',
    verbose_errors  => 1,
    );

ok ( defined ($editor) && ref $editor eq 'HTML::DBForm', 
    'new() works' );

ok ( $editor->element( column => 'headline', size => 50  ), 
    'element() works' );

$search = HTML::DBForm::Search->new('dropdown',
    { columns  => ['test', 'test'] },
     );

ok ( defined ($search) && ref $search eq 'HTML::DBForm::Search::DropDown', 
    'dropdown search works');


$search = HTML::DBForm::Search->new('tablelist',
    { columns  => ['test', 'test'] },
     );

ok ( defined ($search) && ref $search eq 'HTML::DBForm::Search::TableList', 
    'tablelist search works');


