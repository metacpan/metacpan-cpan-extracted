//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
module testmodule (
	clock, reset_n,
	myin, myout);

	input clock;
	input reset_n;
	input myin;
	output outwire;
	output myout;
	reg myout;

	reg [  8'd3 + 8'd4 * 8'd5 : 0 ] temp_reg1;
	reg [ (8'd3 + 8'd4) * 8'd5 : 0 ] temp_reg2;

	wire mywire;
	assign mywire = myin;

	assign outwire = mywire;

	always @(posedge clock or negedge reset_n)
	begin
		if (!reset_n)
			begin
			myout <= junk;
			end
		else
			begin
			myout <= myin;
			end 
	end 



endmodule

