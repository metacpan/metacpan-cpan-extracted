#########################

use Test::More tests => 4;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


    use Encode::Mapper;     ############################################# Enjoy the ride ^^

    use Encode::Mapper ':others', ':silent';    # syntactic sugar for compiler options ..

    Encode::Mapper->options (                   # .. equivalent, see more in the text
            'others' => sub { shift },
            'silent' => 1,
        );

    Encode::Mapper->options (                   # .. resetting, but not to use 'use' !!!
            'others' => undef,
            'silent' => 0
        );

    ## Types of rules for mapping the data and controlling the engine's configuration #####

    @rules = (
        'x',            'y',            # single 'x' be 'y', unless greediness prefers ..
        'xx',           'Y',            # .. double 'x' be 'Y' or other rules

        'uc(x)x',       sub { 'sorry ;)' },     # if 'x' follows 'uc(x)', be sorry, else ..

        'uc(x)',        [ '', 'X' ],            # .. alias this *engine-initial* string
        'xuc(x)',       [ '', 'xX' ],           # likewise, alias for the 'x' prefix

        'Xxx',          [ sub { $i++; '' }, 'X' ],      # count the still married 'x'
    );

    ## Constructors of the engine, i.e. one Encode::Mapper instance #######################

    $mapper_A = Encode::Mapper->compile( @rules );        # engine constructor
    $mapper_B = Encode::Mapper->new( @rules );            # equivalent alias

    is_deeply $mapper_A, $mapper_B, 'constructor identity';

    ## Elementary performance of the engine ###############################################

    @source = ( 'x', 'xx', 'xxuc(x)', 'xxx', '', 'xx' );    # distribution of the data ..
    $source = join '', @source;                             # .. is ignored in this sense

    @result_A = ($mapper_A->process(@source), $mapper_A->recover());  # the mapping procedure
    @result_B = ($mapper_B->process($source), $mapper_B->recover());  # completely equivalent

    is_deeply \@result_A, \@result_B, 'performance identity';

    $result = join '', map { ref $_ eq 'CODE' ? $_->() : $_ } @result_A;

        # maps 'xxxxxuc(x)xxxxx' into ( 'Y', 'Y', '', 'y', CODE(...), CODE(...), 'y' ), ..
        # .. then converts it into 'YYyy', setting $i == 2

    is $result, 'YYyy', 'expected output';
    is $i, 2, 'expected side effect';

    #@follow = $mapper->compute(@source);    # follow the engine's computation over @source
    #$dumper = $mapper->dumper();            # returns the engine as a Data::Dumper object

    ## Module's higher API implemented for convenience ####################################

    #$encoder = [ $mapper, Encode::Mapper->compile( ... ), ... ];    # reference to mappers
    #$result = Encode::Mapper->encode($source, $encoder, 'utf8');    # encode down to 'utf8'

    #$decoder = [ $mapper, Encode::Mapper->compile( ... ), ... ];    # reference to mappers
    #$result = Encode::Mapper->decode($source, $decoder, 'utf8');    # decode up from 'utf8'
