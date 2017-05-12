#!lleval
main = mapM_ (putStrLn . fizzbuzz) [1..30]

fizzbuzz n
   = if or $ map (\s->length s /= 0) [fizz, buzz] 
        then fizz ++ buzz 
        else show n
     where fizz = if mod n 3 == 0 then "Fizz" else ""
           buzz = if mod n 5 == 0 then "Buzz" else ""

