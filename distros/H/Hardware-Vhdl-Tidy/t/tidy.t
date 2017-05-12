BEGIN {
    local @INC=('./t', @INC);
    require TestUtils;
    import TestUtils qw( create_tidy_test compare_indentation escape );
}

use Test::More qw/no_plan/;
use File::Temp qw/tempfile/;
use strict;
use warnings;

# Tests that should be added:
#  all in/out interfaces to tidy_vhdl
#  tidy_vhdl_file
#  all indenting structures
#  tidy_vhdl_file

BEGIN {
    use_ok('Hardware::Vhdl::Tidy');
}

for my $desttype (qw(arrayref fileglob stringref subref)) {
    &test_indent('process lite 1 with destination supplied as '.$desttype, 
    "--process
process
begin
    wait on foo;
    t <= al-foo*5;
    t <= al-foo;
    q <= t + bar * x;
end
  process
  ;
-- etc",
        desttype => $desttype,
    );
}

TODO: {
    local $TODO = 'Not implemented yet';
    $Hardware::Vhdl::Tidy::debug = 0;
    
    &test_indent('empty component declaration', 
    "package test_lib is
    component testsuite
    end component;
    
    component timer
      port (clk	:in std_logic;
        reset :in std_logic;
        enable:in std_logic;
        data  :in std_logic_vector (7 downto 0);
        addr  :in std_logic;  -- one bit only
        irq   :out std_logic
      );
    end component;
end test_lib;",
    );
    
    &test_indent('process lite 1 with left-aligned multi-line preprocessor commands', 
    "--process
process
begin
    wait on foo;
#define UARTIO_SPEC   \\
  signal reset : out std_logic; \\
  SIGNAL seluart : out integer range NUARTS-1 DOWNTO 0;  \\
  SIGNAL host_c : out T_WB_MASTER_CONTROL; \\
  SIGNAL host_s : in T_WB_MASTER_STATUS; \\
  sourceline : in natural; \\
  SIGNAL lineno : out natural
    q <= t + bar * x;
end
  process
  ;
-- etc",
    );

    for my $ppp ('##', '-- pragma preproc ') {
        &test_indent("process lite 1 with left-aligned preprocessor prefix='$ppp'", 
"--process
process
begin
    wait on foo;
${ppp}if SIMULATING==1
    t <= al-foo*5;
${ppp}else
    t <= al-foo;
${ppp}endif
    q <= t + bar * x;
end
  process
  ;
-- etc",
            preprocessor_prefix => $ppp,
        );
    }

}

$Hardware::Vhdl::Tidy::debug = 0;
$Hardware::Vhdl::Tidy::debug = 1;
for my $label ('proclabel', '\\_$! : MY odd procEss label...\\') {
    for my $type ('', 'postponed ') {
        &test_indent($type.'process, with all the extras', 
    "--process
${label}:
  ${type}process
      (
        a, 
        b(1 downto 0), 
        c
      ) 
      is
    variable t : integer;
begin
    t <= al-foo;
    q <= t + bar * x;
end
  ${type}process
  ${label}
  ;
-- etc");
    }
}
$Hardware::Vhdl::Tidy::debug = 0;

&test_indent('process lite 1 with indented preprocessor directives', 
"--process
process
begin
    wait on foo;
    #if SIMULATING==1
    t <= al-foo*5;
    #else
    t <= al-foo;
    #endif
    q <= t + bar * x;
end
  process
  ;
-- etc",
    indent_preprocessor  => 1,
);

&test_indent('record type declaration',
"type T_WB_MON_STATUS is record
    -- controls for putting things in the 'expect' queue - these are for use by helper functions
    q_ack	: bit;
    -- status reporting
    retries : natural;
    nqueued : natural; -- number of transactions that the monitor is expecting
end record;
-- etc");

&test_indent('physical type declaration',
"type T_WB_MON_STATUS is range 0 to integer'high units
    micron;
    millimetre = 1000 micron;
    centimetre = 10000 micron;
    metre = 100 centimetre;
end units;
-- etc");

&test_indent('type/access', 
"type
  name
  is
  access
    datatype
      ;
-- etc
");

&test_indent('architecture, process, loops, generate, min labels',
"architecture ArchName of EntName is
begin
    process 
        variable t : integer;
    begin
        while t<15 loop
            -- sequential statements 1
            seq1a;
            seq1b;
        end loop;
        for I in A'Range loop
            -- sequential statements 2
            seq2;
        end loop;
        loop
            -- sequential statements 3
            seq3;
        end loop;
    end process P;
    G1: for I in A'Range generate
        -- concurrent statements 1
        conc1;
    end generate;
    G2: if cond generate
        -- concurrent statements 2
        conc2;
    end generate;
end ArchName;
-- etc");

&test_indent('architecture, process, loop, generate, max labels',
"architecture ArchName of EntName is
begin
    process 
        variable t : integer;
    begin
        L1: for I in A'Range loop
            -- sequential statements 1
            seq1;
        end loop L1;
        L2: loop
            -- sequential statements 2
            seq2;
        end loop L2;
    end process P;
    G1: for I in A'Range generate
        -- concurrent statements 1
        conc1;
    end generate G1;
    G2: if cond generate
        -- concurrent statements 2
        conc2;
    end generate G2;
end ArchName;
-- etc");


&test_indent('architecture, process, if/then/elsif/else/end if',
"architecture ArchName of EntName is
begin
    process 
        variable t : integer;
    begin
        if a = 1 then
            b <= 1;
        elsif a = 2 then
            b <= 2;
        else
            b <= 3;
        end if;
    end process;
end ArchName;
");

for my $type ('', 'postponed ') {
    &test_indent($type.'process lite 1', 
"--process
${type}process
begin
    wait on foo;
    t <= al-foo;
    q <= t + bar * x;
end
  ${type}process
  ;
-- etc");
}

for my $type ('', 'postponed ') {
    &test_indent($type.'process lite 2', 
"--process
${type}process
    variable t : integer;
begin
    wait on foo;
    t <= al-foo;
    q <= t + bar * x;
end
  ${type}process
  ;
-- etc");
}


for my $type ('', 'pure ', 'impure ') {
    &test_indent($type.'function definition', 
"-- definitions
${type}function  funcname
      (
        foo : integer;
        constant bar : integer := 1;
        signal x:std_logic
      )
      return
      std_logic_vector( 3 downto 0 )
      is
    alias al is sid;
    variable t : integer;
begin
    t <= al-foo;
    return t + bar * x;
end
  function
  funcname
  ;
-- etc");

}

for my $type ('', 'pure ', 'impure ') {
&test_indent($type.'function declaration', 
"-- declaration
${type}function  funcname
      (
        foo : integer;
        constant bar : integer := 1;
        signal x:std_logic
      )
      return
      std_logic_vector( 3 downto 0 )
      ;
-- etc
");
}

&test_indent('procedure declaration', 
"-- declaration
procedure  procname
      (
        foo : integer;
        constant bar : integer := 1;
        signal x:inout std_logic
      )
      ;
-- etc
");

&test_indent('procedure body', 
"-- declaration
procedure  procname
      (
        foo : integer;
        constant bar : integer := 1;
        signal x:inout std_logic
      )
      is
    alias al is sid;
begin
    x <= foo + bar;
end
  procedure
  procname;
-- etc");

&test_indent('configuration declaration', 
"configuration
      topmixed
      of
      top
      is
    for structure
        for b1: blk
            use entity work.blk(rtl);
        end for;
        for b2: blk
            use entity work.gatelevelblk(synth)
              port map (ip => ip1,
                to_int8(x) => y );
        end for;
        for b3: hblkend
            for b4: subblk
                use configuration wurble;
            end for;
        end for;
    end for;
end topmixed;
-- etc");

&test_indent('configuration specifiation',
"architecture a of b is
begin
    for instname : compname
        use entity work.blk(rtl);
    siggy <= soggy;
    for i2, i3 : compname2
        use entity work.blk(rtl)
          port map (ip => ip1,
            to_int8(x) => y );
end
  archname;
");

&test_indent('aggregate', 
"signal
  <=
  (
    A => 1,
    B => 2,
    (
        C or D
    )
    => 3,
    others => 4
  )
  ;
-- etc
");

&test_indent('brackets', 
"((FOO((
                a
            )
        ))
    b ( c )
)");

&test_indent('misc1', 
"PACKage
      bar
      baz
      is
    foo
      ;
    foo
      ;
begin
    foo
      (
        bar
        baz
      )
      ;
    bar
      ;
end
  foo
  ;
");

&test_indent('architecture/component 1', 
"library ieee;
use ieee.std_logic_1164.all;
architecture
      archname
      of
      entname
      is
    signal siggy,
      soggy: std_logic_vector(7 downto 0);
    component
        mux4
          port map (
            d : in std_logic;
            q : out std_logic;
          );
    end component;
begin
    siggy <= soggy;
end
  archname;
");

&test_indent('architecture/component 2', 
"architecture
      anotherarchname
      of
      entname
      is
    signal siggy,
      soggy: std_logic_vector(7 downto 0);
    component mux4 is
          generic map (
            t : integer )
          port map (
            d : in std_logic;
            q : out std_logic;
          );
    end component;
begin
    siggy <= soggy;
end
  architecture
  anotherarchname;
");

&test_indent('syntax summary: entity',
"library IEEE;
use IEEE.Std_logic_1164.all;
entity EntName is
    port (P1, P2: in Std_logic;
        P3: out Std_logic_vector(7 downto 0));
end EntName;
-- etc");

&test_indent('syntax summary: architecture',
"architecture ArchName of EntName is
    component CompName
          port (P1: in Std_logic;
            P2: out Std_logic);
    end component;
    signal SignalName, SignalName2: Std_logic := 'U';
begin
    P: process (P1,P2,P3) -- Either sensitivity list or wait statements!
        variable VariableName, VarName2: Std_logic := 'U';
    begin
        SignalName <= Expression after Delay;
        VariableName := Expression;
        ProcedureCall(Param1, Param2, Param3);
        wait for Delay;
        wait until Condition;
        wait;
        if Condition then
            -- sequential statements 1
        elsif Condition then
            -- sequential statements 2
        else
            -- sequential statements 3
        end if;
        case Selection is
            when Choice1 =>
                -- sequential statements 4
            when Choice2 | Choice3 =>
                -- sequential statements 5
            when others =>
                -- sequential statements 6
        end case;
        for I in A'Range loop
            -- sequential statements 7
        end loop;
    end process P;
    SignalName <= Expr1 when Condition else Expr2;
    InstanceLabel: CompName port map (S1, S2);
    L2: CompName port map (P1 => S1, P2 => S2);
    G1: for I in A'Range generate
        -- concurrent statements 8
    end generate G1;
end ArchName;
-- etc");

&test_indent('syntax summary: package',
"package PackName is
    type Enum is (E0, E1, E2, E3);
    subtype Int is Integer range 0 to 15;
    type Mem is array (Integer range <>) of
      Std_logic_vector(7 downto 0);
    subtype Vec is Std_logic_vector(7 downto 0);
    constant C1: Int := 8;
    constant C2: Mem(0 to 63) := (others => \"11111111\");
    procedure ProcName (ConstParam: Std_logic;
            VarParam: out Std_logic;
            signal SigParam: inout Std_logic);
    function \"+\" (L, R: Std_logic_vector)
          return Std_logic_vector;
end PackName;
-- etc");

&test_indent('syntax summary: package body',
"package body PackName is
    procedure ProcName (ConstParam: Std_logic;
            VarParam: out Std_logic;
            signal SigParam: inout Std_logic) is
        -- declarations
    begin
        -- sequential statements
    end ProcName;
    function \"+\" (L, R: Std_logic_vector)
          return Std_logic_vector is
        -- declarations
    begin
        -- sequential statements
        return Expression;
    end \"+\";
end PackName;
-- etc");

&test_indent('syntax summary: configuration',
"configuration ConfigName of EntityName is
    for ArchitectureName
        for Instances: ComponentName
            use LibraryName.EntityName(ArchName);
        end for;
    end for;
end ConfigName;
");

&test_indent('architecture, process, case',
"architecture ArchName of EntName is
begin
    process 
        variable t : integer;
    begin
        case Selection is
            blah;
            when
              Choice1 
              =>
                t
                  :=
                  1
                  ;
                -- sequential statements
                t:=4;
            when 
              Choice2 
              | Choice3 
              =>
                nested_case: case another_selection is
                    when
                      ab
                      =>
                        t:=23;
                    when cd => t := 42;
                    when others =>
                        t:=i;
                        t:=sin(t);
                end case nested_case;
            when others =>
                t:=5;
        end case;
    end process;
end ArchName;
-- etc");

&test_indent('process lite 1 with left-aligned preprocessor commands', 
"--process
process
begin
    wait on foo;
#if SIMULATING==1
    t <= al-foo*5;
#else
    t <= al-foo;
#endif
    q <= t + bar * x;
end
  process
  ;
-- etc",
);

&test_indent('process lite 1 with initial indent', 
"    --process
    process
    begin
        wait on foo;
        t <= al-foo*5;
        q <= t + bar * x;
    end
      process
      ;
    -- etc",
    starting_indentation  => 1
);

&test_indent('process lite 1 with indentation settings of 3+1', 
"--process
process
begin
   wait on foo;
   t <= al
    -foo*5;
   for x in 1 to 5 loop
      q <= t
       + bar
       * x;
   end loop;
end
 process
 ;
-- etc",
    indent_spaces  => 3,
    cont_spaces => 1,
);

&test_indent('process lite 1 with indentation settings of 3+0', 
"--process
process
begin
   wait on foo;
   t <= al
   -foo*5;
   q <= t + bar * x;
end
process
;
-- etc",
    indent_spaces  => 3,
    cont_spaces => 0,
);

&test_indent('process lite 1 with indentation settings of 3+1, tab_spaces=4', 
"--process
process
begin
   wait on foo;
   t <= al
\t-foo*5;
   for x in 1 to 5 loop
\t  q <= t
\t   + bar
\t   * x;
   end loop;
end
 process
 ;
-- etc",
    indent_spaces  => 3,
    cont_spaces => 1,
    tab_spaces => 4,
);


&test_indent('process lite 1 with indentation settings of 3+1, tab_spaces=2', 
"--process
process
begin
\t wait on foo;
\t t <= al
\t\t-foo*5;
\t for x in 1 to 5 loop
\t\t\tq <= t
\t\t\t + bar
\t\t\t * x;
\t end loop;
end
 process
 ;
-- etc",
    indent_spaces  => 3,
    cont_spaces => 1,
    tab_spaces => 2,
);

sub test_indent {
    my ($testname, $vhdl, %args) = @_;

    # unpack args
    my $srctype = 'arrayref';
    my $desttype = 'arrayref';
    if (exists $args{sourcetype}) {
        $srctype = $args{sourcetype};
        delete $args{sourcetype};
    }
    if (exists $args{desttype}) {
        $desttype = $args{desttype};
        delete $args{desttype};
    }

    # generate the test case (input and desired output)
    my ($correct_tidy_ref, $untidy_ref) = create_tidy_test($vhdl);

    # set up the input thing
    $args{source} = $untidy_ref;

    # set up the output thing
    my $tidy_output;
    if ($desttype eq 'fileglob') {
        $tidy_output = tempfile;
        binmode $tidy_output;
        $args{destination} = $tidy_output;
    }
    elsif ($desttype eq 'stringref') {
        $tidy_output = '';
        $args{destination} = \$tidy_output;
    }
    elsif ($desttype eq 'arrayref') {
        $tidy_output = [];
        $args{destination} = $tidy_output;
    }
    elsif ($desttype eq 'subref') {
        $tidy_output = {};
        my $i=0;
        $args{destination} = sub {
            $tidy_output->{$i++} = shift;
        };
    }
    else {
        die "Unknown dest. type for test_indent: '$desttype'\n";
    }

    # do the thing we want to test!
    Hardware::Vhdl::Tidy::tidy_vhdl(\%args);

    # retrieve the results from the output thing
    # (make $tidy_output an array ref to the output lines)
    if ($desttype eq 'fileglob') {
        seek $tidy_output, 0, 0;
        $tidy_output = [ readline $tidy_output ];
    }
    elsif ($desttype eq 'stringref') {
        $tidy_output = [ split /(?<=\n)/, $tidy_output ];
    }
    elsif ($desttype eq 'subref') {
        my @lines;
        my $i=0;
        while (exists $tidy_output->{$i}) {
            push @lines, $tidy_output->{$i++};
        }
        $tidy_output = \@lines;
    }

    ok(compare_indentation($correct_tidy_ref, $tidy_output), $testname);
}
