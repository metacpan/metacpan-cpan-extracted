use strict;
use blib;
use Language::Lisp::ECLs;
my $cl = new Language::Lisp::ECLs;

$cl->eval(<<"EOS");
(defun si::universal-error-handler (cformat eformat &rest args)
  (prin1 (format nil "hej-hoj-huj [c=~A] [e=~A] ~A" cformat eformat args)))
EOS

print Language::Lisp::ECLs::_keyword("QWER123")->stringify,";\n";
print $cl->eval("#\\s")->stringify,";\n";
print $cl->makeString(20,$cl->keyword("INITIAL-ELEMENT"), $cl->char("s")),";\n";

my $list = $cl->eval("'(a b c d () () (()) qwerty)");
my $arr = $list->_tie;
if (tied @$arr) {print "TIED!"} else {die "huj"}
print "list len is ".$#$arr."+1; items=@$arr;\n";

my $bignum;
$bignum = $cl->eval("(expt 2 1000)");
print '2^1000=',$bignum->stringify,";\n";

my $frac;
$frac = $cl->eval("3/4");
print '3:4=',$frac->stringify,";\n";
$frac = $cl->eval("3/40000000000000000000000000000000");
print '3:40..0=',$frac->stringify,";\n";
$frac = $cl->eval("40000000000000000000000000000000/3");
print '40..0:3=',$frac->stringify,";\n";

my $h = $cl->eval("(make-hash-table :test #'equal)");
my $ha = $h->_tie;
$h->STORE("qwerty","asdf");
$h->STORE("qWeRtY","AsDf");
$h->STORE("qwerty","aSDf");
print "h-str=",$h->stringify,";\n";
$ha->{qwerty} = 'asdF';
print "h:",$h->stringify,";\n";
print "h:",$ha->{"qwerty"}," or ", $h->FETCH("qwerty"),";\n";
my $maplam = $cl->eval("(lambda (k v) (print (list k v)))");
$cl->maphash($maplam, $h);
print "*\n",$cl->eval(":qwertyasdf")->stringify,"\n";

#$cl->shutdown;
my $nil = $cl->eval("nil");
my $t = $cl->eval("t");
my $t1 = $cl->s("T") or die;
#my $nil1 = $cl->s("NIL") or die;
print "t=".$t->stringify."\nnil=".$nil->stringify."\n";
print "t1=".$t1->stringify."\n";
#print "nil1=".$nil1->stringify."\n";
#print "if=",$cl->if(1,"foo","bar"),";\n";
print $cl->format($nil,"[[~A]]","qwerty"),"\n";
$cl->eval(<<"EOS");
(defun this (a)
  (make-string a :initial-element #\\t))
EOS
for (1,3,5,3,4,1) {
    print "n=$_, this=",$cl->this($_),".\n";
}
my $rr = $cl->prin1("qwerty");
#my $rr = $cl->eval("(frustrated)");
__END__

my $r;
$r = $cl->eval("(defstruct foo
    bar fluffy
)");
print "[$r]\n";
$r = $cl->eval("(make-foo)");
print "[$r]\n";
$r = $cl->eval("(lambda (x) (+ 1 x))");
print "[$r]\n", "s=",$r->stringify,"\n";
my $lam = $cl->eval("(lambda (x y) (+ x y))");
my $lam2 = $cl->eval("(lambda (x) (format nil \"~A\" x))");
print "funcall-", $r->funcall(41),";", $lam->funcall(40,2), ";\n";
my $r21000 = $cl->eval("(expt 2 1000)");
print "[$r21000]\n", "s=",$r21000->stringify,"\n";
my $r21001 = $lam->funcall($r21000,1);
print "tst:",$lam2->funcall($r21001),"\n";
#$cl->eval("setq si:*break-enable* nil");
$r = $cl->eval(<<"EOS");
(defpackage "QW")
EOS
print "[$r]\n",$r->stringify,"\n";

$r = $cl->eval(<<"EOS");
(defun this (a)
  (make-string a :initial-element #\\t))
EOS
for (1,3,5,3,4,1) {
    #print "n=$_, this=",$cl->this($_),".\n";
}

$r = $cl->eval(<<"EOS");
'qw::erty
EOS
print "[$r]\n",$r->stringify,"\n";

$r = $cl->eval(<<"EOS");
'qwerty
EOS
print "[$r]\n",$r->stringify,"\n";

$r = $cl->eval(<<"EOS");
(this 50)
EOS
print "[$r]\n";# n/a,$r->stringify,"\n";

