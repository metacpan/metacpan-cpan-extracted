(load "connect")

(prin1 (perl::ev "print STDERR qq/\\nhello from perl!/;('a'..'c')"))
(prin1 (perl::ev "print STDERR qq/\\nhello2 from perl!/;sub test {print STDERR qq/excercising @_;\\n/;$_[0] =~ /$_[1]/g};1"))
(prin1 (perl::call "test" "gdhs67dghw5656gh" "(\\d+)"))

(prin1 (perl::ev "
    use strict;
    use Tcl::Tk;
    use blib;
    use Language::Lisp;
    my $mw = Tcl::Tk::tkinit;
    my $int = $mw->interp;
    my $f = $mw->Frame->pack(-fill=>'both',-side=>'top');
    my $f0 = $mw->Frame->pack(-fill=>'x',-side=>'top');
    my $f1 = $f0->Frame->pack(-fill=>'x',-side=>'top');
    my $lb = $f0->Listbox()->pack(-fill=>'y',-side=>'left');
    my $blb0 = $f1->Button(-text=>'tst0')->pack(-side=>'left');
    my $t = $f0->Scrolled('Text',-font=>'Courier 10')->pack(-fill=>'both',-expand=>1);
    $f->Label(-text=>'test string:')->pack(-side=>'left');
    $f->ComboBox(-editable=>1, -font=>'Courier',
	-textvariable=>\\(my $var2val='(format nil \"Hello, w!~%yep!~%\")'),
	-values=>[
          '(quote (1 2 3 7))',
          '\\'(1 2 \\\"ddwededwe\\\" 7)',
          '(quote (qwerty asdf))',
          '\\'(qwerty asdf)',
          '\\'qwerty',
          ':qwerty',
          '(expt 2 64)',
          'pi',
          '(format t \"Hello, w!~%yep!~%\")',
    ])->pack(-side=>'left',-fill=>'x',-expand=>1)->focus;
    my $btn = $f->Button(-text=>'run (F9)', -command => sub {
	    # run the string!
	    $t->insertEnd('result='.Language::Lisp::eval($var2val).\"\\n\");
	    $t->seeEnd;
	})->pack(-side=>'left');
    my $btn2 = $mw->Button(-text=>'current test (F8)', -command => sub {
	$var2val = ':qwerty';
	print qq<Hoola! var2val=$var2val\\n>;
	$btn->invoke;
    })->pack;
    $mw->bind('<F9>', sub {$btn->invoke});
    $mw->bind('<F8>', sub {$btn2->invoke});
    $int->MainLoop;
    'qwerty'; # this is the result of Perl execution, returned to Lisp
"))

; :vim ft=lisp

