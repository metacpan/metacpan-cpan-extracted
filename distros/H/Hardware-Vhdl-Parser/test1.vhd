LIBrary IEEE;

-- -----------------------------------------------
-- comment_one
-- -----------------------------------------------
-- comment_two
-- -----------------------------------------------

package mypackage is

	type mytype;

	-- -----------------------------------------------
	-- comment_one
	-- -----------------------------------------------
	-- comment_two
	-- -----------------------------------------------

	function my_function return mytype;

	function my_function(a,b,c:std_logic_vector(2 downto 0)) return mytype;

	type myenumeratedtype is ( bingo  ,  bango );

end  ;

package body mypackage is

	function my_function return mytype is
	
	begin

		Case yada is
			when fist_choice => null;
		end case ;

	end function ;

	-- -----------------------------------------------
	-- comment_one
	-- -----------------------------------------------
	-- comment_two
	-- -----------------------------------------------


	procedure yada is
	
	begin

		if true then
			a <= b;
		end if ;

	end procedure ;




end  ;

entity my_entity_name is 
port (
	clock	: in std_logic;
	reset_n : in std_logic;
	
	data_in  : in  wide_data_type;
	data_out : out wide_data_type;

	mp_write_enable	: in	std_logic; 
	mp_address	: in	std_logic_vector( 7 downto 0);  
	mp_write_data	: in	std_logic_vector(11 downto 0);  
	mp_read_data	: out	std_logic_vector(11 downto 0)
	);
end my_entity_name;


architecture rtl of my_entity_name is

	constant LAST_ADDRESSES_TO_TEST   : std_logic_vector ( 9 downto 0 ) 
		:= "1011011000"; 

	component my_sub_entity_name  
	generic (
		length : integer := 1; 
		depth : integer := 1 
		);
	port (
	
		clock	: in std_logic;
		reset_n : in std_logic;
		
		  narrow_data_in_a : in std_logic_vector( 7 downto 0 );
		narrow_data_in_b : in std_logic_vector( 7 downto 0 );
		 narrow_data_in_c : in std_logic_vector( 7 downto 0 );
		
		  narrow_data_out_a : out std_logic_vector( 7 downto 0 );
		narrow_data_out_b : out std_logic_vector( 7 downto 0 );
		 narrow_data_out_c : out std_logic_vector( 7 downto 0 );

		mp_write_enable	: in	std_logic; 
		mp_address	: in	std_logic_vector( 7 downto 0);  
		mp_write_data	: in	std_logic_vector(11 downto 0);  
		mp_read_data	: out	std_logic_vector(11 downto 0)
		);
	end component;

	signal bypass  : std_logic register;
	signal narrow_data_in_a : std_logic_vector( 7 downto 0 );
	signal narrow_data_in_b : std_logic_vector( 7 downto 0 );
	signal narrow_data_in_c : std_logic_vector( 7 downto 0 );
		
	signal 	narrow_data_out_a : std_logic_vector( 7 downto 0 );
	signal 	narrow_data_out_b : std_logic_vector( 7 downto 0 );
	signal	narrow_data_out_c : std_logic_vector( 7 downto 0 );
begin

	process (clock, reset_n)
	begin
		if reset_n = '0' then
			summation_unsigned_4   <= '0';
		elsif clock'event and clock = '1' then
			summation_unsigned_4   <= sum;
		end if;
	end process;



	bypass <= '1';

	bypass <= bypass ;

	narrow_data_in_a <= data_in( 23 downto 16);
	narrow_data_in_b <= data_in( 15 downto  8);
	narrow_data_in_c <= data_in(  7 downto  0);

	  red <=   red_original when (bypass_intermediate='1') 
		else   red_calculated;

	DUT : my_sub_entity_name  
	generic map (
		length => narrow_data_in_a'length,
		depth => 1
		) 
	port map (
	
		clock	=> clock,
		reset_n => reset_n,
		
		narrow_data_in_a => narrow_data_in_a,
		narrow_data_in_b => narrow_data_in_b,
		narrow_data_in_c => data_in(  7 downto  0),
		
		narrow_data_out_a => narrow_data_out_a,
		narrow_data_out_b => narrow_data_out_b,
		narrow_data_out_c => narrow_data_out_c,

		mp_write_enable	=> mp_write_enable,
		mp_address	=> mp_address,
		mp_write_data	=> mp_write_data,
		mp_read_data	=> mp_read_data
		);


	data_out <=  narrow_data_out_a & narrow_data_out_b  &
		 narrow_data_out_c;


	product <= signed(coef) * signed(delta);

	process (clock, reset_n)
	begin
		if reset_n = '0' then
			product_signed_14   <= (others=>'0');
		elsif clock'event and clock = '1' then
			product_signed_14   <= product(13 downto 0);
		end if;
	end process;

end rtl;

