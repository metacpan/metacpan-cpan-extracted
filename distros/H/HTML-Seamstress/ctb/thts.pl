XML::DOM
? More familiar with TReeBuilder but XML::Generator::DOM is nice.

--

classes or prototypes

a/ a call should get the node:
   
b/ autoload
-- context-sensitive XML generation?

@children = 

--

callbacks?


--

a package seems to be the natural way to encapsulate the id locations

my $tree = HTML::Seamstress->new_from_file('html/x/y/hello_world.html');
$tree->content_handler(name => $name)->content_handler(date => `date`);
$tree->as_HTML;

my $tree = $S->load('html/main/hello_world.html');
$tree->name('bob')->date(`date`)

HTML::main::hello_world->new
  ->content_handler(name => 'bob')
  ->content_handler(date => `date`)
  ->as_HTML;

HTML::main::hello_world
  ->name('bob')
  ->date(`date`)
  ->as_HTML;

<span id="age_dialog">
    <span id="under10">
       Hello, does your mother know you're 
       using her AOL account?
    </span>
    <span id="under18">
       Sorry, you're not old enough to enter 
       (and too dumb to lie about your age)
    </span>
    <span id="welcome">
       Welcome
    </span>
</span>

my $age = $cgi->param('age');
my $a = HTML::auth::results->new;
$a->age_dialog(
	       [
		under10 => sub { $_[0] < 10} , 
		under18 => sub { $_[0] < 18} ,
		welcome => sub { 1 }
	       ],
	       $age
	      );

---

my @data =
  ('the pros' => 'never have to worry about service again',
   'the cons' => 'upfront extra charge on purchase',
   'our choice' => 'go with the extended service plan');

my $dl = HTML::dl->new;
$dl->service_plan(@data);

     
