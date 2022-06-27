Host: example.com
Content-Type: multipart/mixed;
     boundary=unique-boundary-1

The preamble of the outer multipart message.
Content readers that understand multipart format
should ignore this preamble.
If you are reading this text, you might want to
consider changing to a content reader that understands
how to properly parse multipart messages.
--unique-boundary-1

Part 1 of the outer message.
[Note that the preceding blank line means
no header fields were given and this is text,
with charset US ASCII. It could have been
done with explicit typing as in the next part.]

--unique-boundary-1
Content-type: text/plain; charset=utf-8

Part 2 of the outer message.
This could have been part of the previous part,
but illustrates explicit versus implicit
typing of body parts.

--unique-boundary-1
Content-Type: multipart/form-data;
    boundary=unique-boundary-2
X-Description: Part 3 of the outer message is multipart!

A one-line preamble for the inner multipart message.
--unique-boundary-2
Content-Type: image/png
Content-Encoding: base64
Content-Disposition: form-data; name="image1"; filename="tengu-2.png"
X-Description: Part 1 of the inner message is a png, "tengu-2.png"

iVBORw0KGgoAAAANSUhEUgAAABUAAAAWCAIAAACg4UBvAAADEklEQVR4nGL4TxlgoKb+f58+fVm0
5GVl7YPZcx9t3vr84KH7O3ddW77y+rLlH548QdH37x+6/j9AtGnjH2Pjd5o675R1HynqXFHUPiir
vl5UfiW/5IbIuD9//uCz/9+XL/+6Ot6balfqKPerqhxR0zmprrNDRWuDitZGWeUp2gb3rl3Dp//v
u3c/y8r+mRu26yvJS4voSohXycsvVFKZo6DaK6vgIC25Y/vWf///4db/+vX3rJz/xsaPbHUzpPnF
eTnlRYSK5GWnKiqGysqI8HEtmdT/H8MLSP5//vx7XMIfJeXbeSlnJ01YaGPmJ8prJCJYpSBjIy0W
Ki15pKby18cPuO1/+vRraPgrMbGbLdUnr13I8XYqFxWoExdslhaLEBb0VJPfO7Xv37dvuMPv4cOv
QYEPpMSOe9sUJwRKSgvkCgsdk5VZqi3vryIrK8a7ack8kDX/sOkHCv65deu7h9tHA6Vn9ur7rDS6
tFTWyyh90zS6oKVTqqGSKCWxKz7xfVPTlZzc52fO/EOLfyDv96VL3x3t/9sY/vM0/eNs+NNS/4eF
wR9bu/fKegf5pQ4KynzS0nlupjZPlG+2u9v3T5/Q9f+8cPGLtc03Pe13Nnpf3fSe2ahdMVN4ban7
Wl3nvKT8bjGZcwoKmxTFmnnZF4aH/fz6FV3/r5s3ntnYr5ORydNX69GSm60sNlVOeJWU+CxBsRIe
gUIegRZZxdmGpou8vJ9fvgwPBET4/X775mZSSi+fAI8oLzsvpw4XWygvd4GocLqomAcXtz2/wNJJ
Ex5du/YdZjNG/P3//3T//jXq2rVCAjEiXJHqkhW+Tp2hXhOCXXu9bZv8PN+/ffMfA6Dkv9+/fx1v
btkjLHFYUWaTm+mOWK9Fdkb92ioTDTU3FeX9Q0+7GPr//v/3/umTOTomq7iF9inKbNeQmKEg1Com
0CYrd3rZEmzasZUf1/cdmBkUMk9JZb2Y0CxZgTphvgk2tp/fvsWmHaIf1WXAtPH18+eXd++enjp1
ibf7XF+fG7t3/cWqm8rlFxkAAAAA//8DAB1sApdpwz9dAAAAAElFTkSuQmCC
--unique-boundary-2
Content-Type: image/png
Content-Encoding: base64
Content-Disposition: form-data; name="image2"; filename="oni.png"
X-Description: Part 2 of the inner message is another png, "oni.png"

iVBORw0KGgoAAAANSUhEUgAAABYAAAAUCAIAAAAGHlpnAAADwElEQVR4nGL4TzFgwBT69///lzt3
Xly+8OLp4+dPH71++fzj+7fvb938eOP633//kNT9w27E9+/fjx8/dDY2ZLOVYYy7dYCLaYinZVaQ
ywl3h+2BXvsO7P765RM+V/z88X35gukm+vJTlOSPKqk78XGKczFKcTEG8nPuk1fOlxS1NFScPaXr
25cv2I349//fgV2bLfXkdfnZFksq3lXSXy2jWioi2SIus19R66SCbpWYjJYgq7mm1LFDe7EY8e/f
v1vXLsYEOlsJcM6XVPhqY/ffye6Lidl7I5P/9nb/3Zz/2lieU9dJFxTWE2DNTAh99uQRuhG/f/2a
2FGjw8c8V0zmv5n5Jzf9907qHx20Proa/o1z/BFi9sRY7raW7BY5xWQBAXV+5lmTu//8/o1ixM8f
P6qK01y4WK7IKH92sX7W1XSzpuyBvcF3b52vfrq3XIxvtDTeb645qafRLiRiyMWYnxr1/ds3FCOe
PnnobKGTwMn+REHlRVv1jr3b+/vad8T6fHbQv2OqdrImf9Wm1YsXzzqaELRAVNSdk9nNUgfuF6gR
B3ZvUxJmLeTmea+qdbu52M7TWlSMd76/7QcTk+MamvOSgzW05LV01fcl+W2QkwvkZNeR5jt97CCK
EXu2rlcTZa8UEPykpvfS16XAXCdFVfa0o/FbI+MdSqqb7A1zjNTzjTTOW5ktl5L35+VWFWbdsWk1
ihG7tqzVFGKbJCL+39L8u4/1Tw/jD1aab/Q1vpiZbFFVOWig8j/Y4o+n8T1Dzd1KKqkC/BpCLLu2
rEcx4vzp4zrivE2CIg9U1Peoyd801/jgYv5UR/udnsZ2RZnl8rKvXUyfmmnuU5RdLyObxM9jKCd4
6thhFCOePX7oaKTizM0+XVC8l5N/mYvTg6m9p1IT9jrZz7c0XRHsf72n9bCLy3QugRoBYUsuFjcL
7edPH6MY8ffP742rFunICTpzs7Vx88/3dJ8VG7mqMPfYyvn7F05bmZm2IjFukadHMQePNReLnoLI
yiVzfv36iZ7Af/783tdaK8/D6M7NUScg0SgisdLL/URB5pnCzA3eHu2ikmWC4nbcbIoCLLOm9Hz/
/g17Hnn35lV9abayEJsJC4MvC0saN08Fj2A1j0gmj4AvK5s+A4O6BP+c6f0/kPT/x8zsnz9+OLB7
a0ZcsLmqlBoXowYTgzoTgyIrg76cSHyI147N64G5GU0LzAiksgSY5T59/PDw3p2De7dP7mltqCyY
N3PSzetXvn75/O/v3/8YAEupRSoAAAAA//8DABTUSlT+h8PYAAAAAElFTkSuQmCC
--unique-boundary-2--

The epilogue for the inner multipart message.

--unique-boundary-1
Content-type: text/richtext

This is <bold>part 4 of the outer message</bold>
<smaller>as defined in RFC1341</smaller><nl>
<nl>
Isn't it <bigger><bigger>cool?</bigger></bigger>

--unique-boundary-1
Content-Type: message/http; name="/evil/filename";

GET / HTTP/1.1
Host: www.example.org
Content-Type: text/plain; charset=utf-8
Content-Encoding: Quoted-printable

Part 5 of the outer message is itself an http message!

--unique-boundary-1--

The epilogue for the outer message.

