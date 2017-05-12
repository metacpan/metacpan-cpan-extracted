#!lleval
let fizzbuzz n =
  let fizz = if n mod 3 == 0 then "Fizz" else "" in
  let buzz = if n mod 5 == 0 then "Buzz" else "" in
  if [] != List.filter (fun s -> String.length s != 0) [fizz;buzz]
     then fizz ^ buzz
     else string_of_int n

let puts s = print_string( s ^ "\n");;

for i = 1 to 30 do
  puts (fizzbuzz i)
done;;

