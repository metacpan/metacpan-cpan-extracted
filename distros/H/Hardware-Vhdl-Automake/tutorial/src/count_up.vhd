--< compiler_option check_for_synthesis 1 >--

library ieee ;
use ieee.std_logic_1164.all;

entity count_up is
    generic (
        NBITS : positive := 8
      );
    port (
        clk   : in std_logic;
        reset : in  std_logic;
        
        b     : in  std_logic_vector(NBITS-1 downto 0);
        q     : out std_logic_vector(NBITS downto 0)
      );
end count_up ;

-----------------------------------------------------------------------------------------

architecture struct of count_up is

    signal count   : std_logic_vector(NBITS-1 downto 0);
    signal sum     : std_logic_vector(NBITS downto 0);
    signal const_1 : std_logic_vector(NBITS-1 downto 0);
    
    --< COMPONENT work.adder >--

begin
    const_1 <= (0 => '1', others => '0');

    adder_i: adder
      generic map (
        NBITS => NBITS
      )
      port map (
        clk   => clk,
        reset => reset,
        a     => sum(NBITS-1 downto 0),
        b     => const_1,
        q     => sum
      );
    
    count <= sum(NBITS-1 downto 0);
    
end struct;