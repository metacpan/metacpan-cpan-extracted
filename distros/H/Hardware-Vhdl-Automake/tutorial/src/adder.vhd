--< compiler_option check_for_synthesis 1 >--

library ieee ;
use ieee.std_logic_1164.all;

entity adder is
    generic (
        NBITS : positive := 8
      );
    port (
        clk   : in std_logic;
        reset : in  std_logic;
        
        a     : in  std_logic_vector(NBITS-1 downto 0);
        b     : in  std_logic_vector(NBITS-1 downto 0);
        q     : out std_logic_vector(NBITS downto 0)
      );
end adder ;

-----------------------------------------------------------------------------------------

library ieee ;
use ieee.numeric_std.all;

architecture rtl of adder is
    signal a_padded, b_padded : unsigned(NBITS downto 0);
begin
    a_padded <= '0' & unsigned(a);
    b_padded <= '0' & unsigned(b);
    
    reg_adder: process (clk, reset)
    begin
        if reset='1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            q <= std_logic_vector(a_padded + b_padded);
        end if;
    end process;
    
end rtl;