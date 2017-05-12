-- ----------------------------------------------------------------- --
--      This Lua5 module is Copyright (c) 2010, Peter J Billam       --
--                        www.pjb.com.au                             --
--                                                                   --
--   This module is free software; you can redistribute it and/or    --
--          modify it under the same terms as Lua5 itself.           --
-- ----------------------------------------------------------------- --
local M = {} -- public interface
M.Version = '1.17'
M.VersionDate = '12aug2010'

-- Example usage:
-- local WT = require 'WalshTransform'
-- H = WT.fht(a)

--------------------- infrastructure ----------------------
local function warn(str)
    io.stderr:write(str,'\n')
end
local function die(str)
    io.stderr:write(str,'\n')
    os.exit(1)
end
local function jw2jh(n)
	if (n < 16) then
		if n == 8 then return {0,4,6,2,3,7,5,1}; end
		if n == 4 then return {0,2,3,1}; end
		if n == 2 then return {0,1}; end
		if n == 1 then return {0}; end
		warn "jw2jh: n=$n must be power of 2\n"; return false;
	end
	local half_n = n / 2;
	local half = jw2jh(half_n)
	local whole = {}
	local i = 1; while i <= half_n do
		whole[i] = 2 * half[i]
		i = i + 1
	end
	i = half_n; local j = half_n + 1
	while i >= 1 do
		whole[j] = 1 + whole[i]
		i = i - 1
		j = j + 1
	end
	return whole
end
-------------------------------------------------------

function M.fht(a)
	local i; local mr = {}; for i=1,#a do mr[i] = a[i] end
	local k = 1
	local n = #mr
	local l = n
	local nl; local nk; local j;
	while true do
		i = 0; l = l/2;
		for nl=1,l do
			for nk=1,k do
				i = i + 1; j = i + k;
				mr[i] = (mr[i] + mr[j])/2;
				mr[j] =  mr[i] - mr[j];
			end
			i = j;
		end
		k = 2*k;
		if k >= n then break end
	end
	if k == n then
		return mr
	else
		warn("WalshTransform::fht \$n = $n but must be power of 2\n")
		return false
	end
end

function M.fhtinv(a)
	local i; local mr = {}; for i=1,#a do mr[i] = a[i] end
	local k = 1;
	local n = #mr;
	local l = n;
	local nl; local nk; local j;
	while true do
		i = 0; l = l/2;
		for nl=1,l do
			for nk=1,k do
				i = i + 1; j = i + k;
				mr[i] = mr[i] + mr[j];
				mr[j] = mr[i] - 2*mr[j];
			end
			i = j;
		end
		k = 2 * k;
		if k >= n then break end
	end
	if k == n then
		return mr;
	else
		warn "WalshTransform::fhtinv \$n = $n but must be power of 2\n";
		return false
	end
end

function M.fwt(a) -- might be easier to Hadamard transform and shuffle results
	local i; local mr = {}; for i=1,#a do mr[i] = a[i] end
	local n = #mr; local nr = {}
	local k; local l; local nl; local nk; local kp1;

	local m = 0  -- will be log2(n)
	local tmp = 1; while tmp < n do
		tmp = tmp * 2
		m = m + 1
	end
	local alternate = (m % 2) > 0.5
	if alternate then
		for k=1, n, 2 do
			kp1 = k + 1
			mr[k]   = (mr[k] + mr[kp1])/2
			mr[kp1] =  mr[k] - mr[kp1]
		end
	else
		for k=1, n, 2 do
			kp1 = k+1
			nr[k]   = (mr[k] + mr[kp1])/2
			nr[kp1] =  nr[k] - mr[kp1]
		end
	end
	k = 1; local nh = n/2;
	while true do
		local kh = k; k = k+k; kp1 = k+1;
		if kp1 > n then break; end
		nh = nh/2; l = 1; i = 1; alternate =  not alternate;
		for nl=1, nh do
			for nk=1, kh do
				if alternate then
					mr[l]   = (nr[i]   + nr[i+k])/2;
					mr[l+1] =  mr[l]   - nr[i+k];
					mr[l+2] = (nr[i+1] - nr[i+kp1])/2;
					mr[l+3] =  mr[l+2] + nr[i+kp1];
				else
					nr[l]   = (mr[i]   + mr[i+k])/2;
					nr[l+1] =  nr[l]   - mr[i+k];
					nr[l+2] = (mr[i+1] - mr[i+kp1])/2;
					nr[l+3] =  nr[l+2] + mr[i+kp1];
				end
				l = l+4; i = i+2;
			end
			i = i+k
		end
	end
	return mr
end

function M.fwtinv(a)
	local i; local mr = {}; for i=1,#a do mr[i] = a[i] end
	local n = #mr; local nr = {}
	local k; local l; local nl; local nk; local kp1;
	local m = 0;  -- log2($n)
	local tmp = 1; while tmp < n do
		tmp = tmp * 2
		m = m + 1
	end
	local alternate = (m % 2) > 0.5
	if alternate then
		for k=1, n-1, 2 do
			kp1 = k + 1
			mr[k]   =  mr[k] + mr[kp1];
			mr[kp1] =  mr[k] - mr[kp1] - mr[kp1];
		end
	else
		for k=1, n-1, 2 do
			kp1 = k + 1
			nr[k]   =  mr[k] + mr[kp1];
			nr[kp1] =  mr[k] - mr[kp1];
		end
	end
	k = 1; local nh = n / 2;
	while true do
		local kh = k; k = k+k; kp1 = k+1;
		if kp1 > n then break; end
		nh = nh/2; l = 1; i = 1; alternate =  not alternate;
		for nl=1, nh do
			for nk=1, kh do
				if alternate then
					mr[l]   =  nr[i]   + nr[i+k];
					mr[l+1] =  nr[i]   - nr[i+k];
					mr[l+2] =  nr[i+1] - nr[i+kp1];
					mr[l+3] =  nr[i+1] + nr[i+kp1];
				else
					nr[l]   =  mr[i]   + mr[i+k];
					nr[l+1] =  mr[i]   - mr[i+k];
					nr[l+2] =  mr[i+1] - mr[i+kp1];
					nr[l+3] =  mr[i+1] + mr[i+kp1];
				end
				l = l+4; i = i+2;
			end
			i = i+k
		end
	end
	return mr
end

function M.logical_convolution(a, b)
	if type(a) ~= 'table' then
		warn("WalshTransform.logical_convolution 1st arg must be a table\n")
		return nil
	elseif type(b) ~= 'table' then
		warn("WalshTransform.logical_convolution 2nd arg must be a table\n")
		return nil
	end
	if #a ~= #b then
		warn("WalshTransform.logical_convolution args must be the same size\n")
		return nil
	end
	local Fa = M.fwt(a);  local Fb = M.fwt(b);
	return M.fwtinv(M.product(Fa, Fb));
end

function M.logical_autocorrelation(mr)
	return M.logical_convolution(mr,mr)
end

function M.power_spectrum(mr)
	return M.fwt(M.logical_convolution(mr, mr) )
end

function M.walsh2hadamard(mr)
	local n = #mr; local h = {}
	local jw2jh_save = jw2jh(n);
	local i; for i=1,n do h[1 + jw2jh_save[i]] = mr[i]; end
	return h
end

function M.hadamard2walsh(mr)
	local n = #mr; local w = {}
	local jw2jh_save = jw2jh(n);
	-- warn('jw2jh_save='..table.concat(jw2jh_save,', '))
	-- warn('n='..n..' #jw2jh_save='..#jw2jh_save)
	local i
	for i=1,n do
		w[i] = mr[1 + jw2jh_save[i]]
	end
	-- warn('n='..n..' #w='..#w)
	return w;
end

------------------------ EXPORT_OK stuff ---------------------------

function M.biggest(k, a)
	local weeded = {}; for i=1,#a do weeded[i] = a[i] end
	local smallest;
	if k <= 0 then
		local tot = 0.0
		for i,v in ipairs(weeded) do tot = tot + math.abs(v); end
		smallest = tot / #weeded
	else
		local sorted = {}
		for i=1,#weeded do sorted[i] = weeded[i] end
		table.sort(sorted, function (a,b) return math.abs(a) > math.abs(b) end)
		smallest = math.abs(sorted[k])
	end
	for i,v in ipairs(weeded) do
		if math.abs(v) < smallest then weeded[i] = 0.0; end
	end
	return weeded
end

function M.sublist(a, offset, length)
	if type(a) ~= 'table' then
		warn("WalshTransform.sublist 1st arg must be a table\n")
		return nil
	end
	local first;
	if offset<0 then first = #a + offset + 1 else first = offset + 1; end
	local last;
	if not length then last = #a
	elseif length < 0 then last = #a + length
	else last = first + length - 1
	end
	local sublist = {}; local i;
	for i=first,last do sublist[#sublist+1] = a[i] end
	return sublist
end

function M.distance(a, b)  -- Euclidian metric
	if type(a) ~= 'table' then
		warn("WalshTransform.distance 1st arg must be a table\n")
		return nil
	end
	if type(b) ~= 'table' then
		warn("WalshTransform.distance 2nd arg must be a table\n")
		return nil
	end
	if #a ~= #b then
		warn("WalshTransform.distance the 2 args must be the same size\n")
		return nil
	end
	local d = 0.0; local i; local diff;
	for i = 1, #a do
		diff = a[i] - b[i];
		d = d + diff * diff
	end
	return math.sqrt(d)
end

function M.size(a)
	local sum=0.0; local i; for i=1,#a do sum = sum + a[i]*a[i] end
	return math.sqrt(sum)
end

function M.product(a,b)
	if type(a) ~= 'table' then
		warn("WalshTransform.product 1st arg must be a table\n")
		return nil
	end
	if type(b) ~= 'table' then
		warn("WalshTransform.product 2nd arg must be a table\n")
		return nil
	end
	if #a ~= #b then
		warn("WalshTransform.product the 2 args must be the same size\n")
		return nil
	end
	local c = {}; local i;
	for i=1,#a do c[i] = a[i]*b[i] end
	return c
end

function M.normalise(a)
	if type(a) ~= 'table' then
		warn("WalshTransform.product 1st arg must be a table\n")
		return nil
	end
	local s = M.size(a);  local normalised = {};  local i
	for i = 1, #a do normalised[i] = a[i]/s end
	return normalised
end

function M.average (...)
	local i = 1; local j; local sum = {}; local n = 0
	for i,a in ipairs({...}) do
		if type(a) ~= 'table' then
			warn("WalshTransform.average arg must be a table\n")
			return nil
		end
		for j=1, #a do sum[j] = (sum[j] or 0) + a[j] end
		n = n + 1
	end
	for j=1,#sum do sum[j] = sum[j] / n end
	return sum
end

return M

--[[

=pod

=head1 NAME

WalshTransform.lua - Fast Hadamard and Walsh Transforms

=head1 SYNOPSIS

 local WT = require 'WalshTransform' -- name doesn't matter of course
 local f = {1.618, 2.718, 3.142, 4.669}  -- must be power-of-two long
 local FH1 = WT.fht(f)   -- Hadamard transform
 local fh1 = WT.fhtinv(FH1)
 -- or
 local FW2 = WT.fwt(f)   -- Walsh transform
 local fw2 = WT.fwtinv(FW2)
 local FH2 = WT.walsh2hadamard(FW2)

 local PS  = WT.power_spectrum(f)

 local whats_going_on = WT.biggest(9,WT.fwt(WT.sublist(time_series,-16)))
 local EVENT1 = WT.fwt(WT.sublist(time_series,478,16))
 local EVENT2 = WT.fwt(WT.sublist(time_series,2316,16))
 local EVENT3 = WT.fwt(WT.sublist(time_series,3261,16))
 EVENT1[1]=0.0; EVENT2[1]=0.0; EVENT3[1]=0.0 -- ignore constant
 EVENT1 = WT.normalise(EVENT1) -- ignore scale
 EVENT2 = WT.normalise(EVENT2)
 EVENT3 = WT.normalise(EVENT3)
 local TYPICAL_EVENT = WT.average(EVENT1, EVENT2, EVENT3)
 ...
 local NOW = WT.fwt(WT.sublist(time_series,-16))
 NOW[1] = 0.0
 NOW = WT.normalise(NOW)
 if WT.distance(NOW, TYPICAL_EVENT) < .28 then get_worried() end

=head1 DESCRIPTION

These routines implement fast Hadamard and Walsh Transforms
and their inverse transforms.

Also included are routines
for converting a Hadamard to a Walsh transform and vice versa,
for calculating the Logical Convolution of two lists,
or the Logical Autocorrelation of a list,
and for calculating the Walsh Power Spectrum -
in short, almost everything you ever wanted to do with a Walsh Transform.

Intelligible speech can be reconstructed by transforming
blocks of, say, 64 samples, deleting all but the several largest
transform components, and inverse-transforming;
in other words, these transforms extract from a time-series
the most significant things that are going on.
They should be useful for B<noticing important things>,
for example in software that monitors time-series data such as
system or network administration data, share-price, currency,
ecological, opinion poll, process management data, and so on.

As from version 1.10, Math::WalshTransform uses C routines to perform
the transforms. This runs 25 to 30 times faster than previous versions.

Not yet included are multi-dimensional Hadamard and Walsh Transforms,
conversion between Logical and Arithmetic Autocorrelation Functions,
or conversion between the Walsh Power Spectrum and the Fourier Power Spectrum.

Version 1.17

=head1 SUBROUTINES

Routines which take just one array as argument expect the array itself;
those which take more than one array expect a list of references.

=over 3

=item I<fht>(f)

The argument I<f> is the list of values to be transformed.
The number of values must be a power of 2.
I<fht> returns a list I<F> of the Hadamard transform.

=item I<fhtinv>(F)

The argument I<F> is the list of values to be inverse-transformed.
The number of values must be a power of 2.
I<fhtinv> returns a list I<f> of the inverse Hadamard transform.

=item I<fwt>(f)

The argument I<f> is the list of values to be transformed.
The number of values must be a power of 2.
I<fwt> returns a list I<F> of the Walsh transform.

=item I<fwtinv>(F)

The argument I<F> is the list of values to be inverse-transformed.
The number of values must be a power of 2.
I<fwtinv> returns a list I<f> of the inverse Walsh transform.

=item I<walsh2hadamard>(F)

The argument I<F> is a Walsh transform;
I<walsh2hadamard> returns a list of the corresponding Hadamard transform.

=item I<hadamard2walsh>(F)

The argument I<F> is a Hadamard transform;
I<hadamard2walsh> returns a list of the corresponding Walsh transform.

=item I<logical_convolution(x, y)>

The arguments are references to two arrays of values I<x> and I<y>
which must both be of the same size which must be a power of 2.
I<logical_convolution> returns a list of the logical (or dyadic) convolution
of the two sets of values.  See the MATHEMATICS section ...

=item I<logical_autocorrelation(x)>

The argument is a list of values I<x>;
the number of values must be a power of 2.
I<logical_autocorrelation> returns a list of the logical (or dyadic)
autocorrelation of the set of values.  See the MATHEMATICS section ...

=item I<power_spectrum(x)>

The argument is a list of values I<x>;
the number of values must be a power of 2.
I<power_spectrum> returns a list of the Walsh Power Spectrum
of the set of values.  See the MATHEMATICS section ...

=item I<biggest(k, x)>

The first argument I<k> is the number of elements of the array I<x>
which will be conserved;
I<biggest> returns an array in which the biggest I<$k> elements
are intact and in place, and the other elements are set to zero.
If I<$k> is 0 or negative, then I<biggest> returns an array in which
all elements less than the average (absolute) size have been set to zero.

=item I<sublist(array, offset, length)>

This routine returns a part of the I<array> without,
as I<splice> does, munging the original array.
It applies to arrays the same sort of syntax that Perl's
I<substr> applies to strings;
the sublist is extracted starting at I<offset> elements from the front
of the array; if I<offset> is negative the sublist starts that far from the
end of the array instead; if I<length> is omitted, everything to the end
of the array is returned; if I<length> is negative, the length is
calculated to leave that many elements off the end of the array.

=item I<distance(array1, array2)>

This routine returns the distance between the two arrays,
according to the Euclidian Metric;
in other words, the square root of the sum of the squares
of the differences between the corresponding elements.

=item I<size(array)>

This routine returns the distance between the array and an array of zeroes,
according to the Euclidian Metric;
in other words, the square root of the sum of the squares of the elements.

=item I<normalise(array)>

This routine returns an array scaled so that its I<size> is 1.0

=item I<average(array1, array2, ... arrayN)>

This routine returns an array in which each element is the average
of the corresponding elements of all the argument arrays.

=item I<product(array1, array2)>

This routine returns an array in which each element is the product
of the corresponding elements of the argument arrays.

=back

=head1 MATHEMATICS

The Hadamard matrix is a square array of plus and minus ones,
whose rows and columns are orthogonal to each other.
Hence, the product of the matrix and its tranpose
is the identity matrix times a constant I<N> which is equal to the
order of the matrix.
If I<N> is a power of two, symmetrical Hadamard matrices can
be defined recursively:

         | 1  1 |
 Had   = |      |
    2    | 1 -1 |

         | Had   Had  |
         |    N     N |
 Had   = |            |
    2N   | Had  -Had  |
         |    N     N |

Each row of the Hadamard matrix corresponds to
a Hadamard Function I<Had(j,k)> where j = 0...N-1

Another way to describe a Hadamard matrix of dimension 2^N x 2^N is
that the entry in row i and column j is (-1)^P, where P is the number
of positions in which the binary expansion of i and j share a 1.
From this definition it is immediate that the last row (and column) is a
Thue-Morse (or Morse-Thue) sequence, and also that rows that are of the
form 2^N - 2^j will be j-fold repetitions of the Thue-Morse sequence.

The upper half of the Hadamard matrix are cycles of increasing
wavelengths, and the lower half are Morse-Thue sequences on
decreasing cell-sizes, much as the components of a
Fourier analysis are sine-waves of different wavelengths.

The Walsh matrix is derived from the Hadamard matrix by rearranging the rows
so that the number of sign-changes is in increasing order.  Each row of the
Walsh matrix corresponds to a Walsh Function I<Wal(j,k)> where j = 0...N-1

The one-dimensional Hadamard transform pair is defined by

 F(j) = (1/N) * Sigma f(k)*Had(j,k)
 f(j) = Sigma F(k)*Had(j,k)

and the one-dimensional Walsh transform pair is defined by

 F(j) = (1/N) * Sigma f(k)*Wal(j,k)
 f(j) = Sigma F(k)*Wal(j,k)

The two transforms are equivalent, and conversion between them
only involves rearranging the order of the components.
Since the Walsh functions are in order of increasing number of sign-changes,
the Walsh transform is more Fourier-like,
and for that reason is used more often,
although it does use several per-cent more CPU time.

Because all the matrix elements are either 1 or -1,
these transforms involve almost no multiplications
and are computationally very efficient.

The Logical (or Dyadic) Convolution of two arrays x and y is defined by

 z(k) = (1/N) * Sigma x(k^j)*y(j)

where the ^ is used in its Perl sense, to mean bitwise exclusive-or.
There exists a Logical (or Dyadic) Convolution Theorem, analogous to the
normal case, that the Walsh transform of the logical convolution of two
sequences is the product of their Walsh transforms,
and that the Walsh transform of the product of two sequences is the
logical convolution of their Walsh transforms.

Likewise there exists a Logical Wiener-Khintchine Theorem,
stating that the Walsh Power Spectrum
is the Walsh transform of the Logical Autocorrelation Function.

There exist linear transformations converting
between Logical Convolution and the normal Arithmetic Convolution,
and between the Walsh Power Spectrum and the normal Fourier Power Spectrum.

=head1 AUTHOR

Peter J Billam, www.pjb.com.au/comp/contact.html

=head1 REFERENCES

I<Walsh Spectrometry,
a form of spectral analysis well suited to binary computation>,
J. E. Gibbs,
National Physical Lab, Teddington, Middlesex, England,
unpublished, 1967

I<Hadamard transform image encoding>,
W. K. Pratt, J. Kane and H. C. Andrews,
Proc. IEEE,
Vol. 57, Jan 1969, pp. 58-68

I<Walsh function generation>,
D. A. Swick,
IEEE Transactions on Information Theory (Corresp.),
Vol. IT-15 part 1, Jan 1969, p. 167

I<Computation of the Hadamard transform and the R-transform in ordered form>,
L. J. Ulman,
IEEE Trans. Comput. (Corresp.),
Vol. C-19, Apr 1970, pp. 359-360

I<Computation of the Fast Hadamard Transform>,
Ying Shum and Ronald Elliot,
Proc. Symp. Appl. Walsh Functions,
Washington D.C., 1972, pp. 177-180

I<Logical Convolution and Discrete Walsh and Fourier Power Spectra>,
Guener Robinson,
IEEE Transactions on Audio and Electroacoustics,
Vol. AU-20 No. 4, October 1972, pp. 271-280

I<Speech processing with Walsh-Hadamard Transforms>,
Ying Shum, Ronald Elliot and Owen Brown,
IEEE Transactions on Audio and Electroacoustics,
Vol. AU-21 No. 3, June 1973, pp. 174-179

=head1 SEE ALSO

 http://www.pjb.com.au/
 http://search.cpan.org/perldoc?Math::WalshTransform
 Math::Evol    http://search.cpan.org/perldoc?Math::Evol
 Term::Clui    http://search.cpan.org/perldoc?Term::Clui
 Crypt::Tea_JS http://search.cpan.org/perldoc?Crypt::Tea_JS
 http://en.wikipedia.org/wiki/Thue-Morse_sequence
 http://mathworld.wolfram.com/WalshTransform.html
 http://arxiv.org/abs/nlin/0510009
 http://arxiv.org/abs/cs/0703057
 perl(1).

]]
